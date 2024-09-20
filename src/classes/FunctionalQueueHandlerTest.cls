/**
 * @description       :
 * @group             :
 * @last modified on  : 11-09-2021
 **/
@IsTest
public with sharing class FunctionalQueueHandlerTest {
	@IsTest
	public static void deleteFunctionalQueueGroups_givenDeletedFunctionalQueue_shouldDeleteCorrespondingGroupAndQueue() {
		Functional_Queue__c testFunctionalQueue = createTestFunctionalQueue('Test Functional Queue terst');
		testFunctionalQueue.RecordTypeID = Schema.SObjectType.Functional_Queue__c.getRecordTypeInfosByDeveloperName()
			.get('Functional_Queue_Default')
			.getRecordTypeId();
		insert testFunctionalQueue;
		Group testGroup = createTestGroup('test public group 123', 'Regular');
		Group testQueue = createTestGroup('test queue 123', 'Queue');
		testFunctionalQueue.Public_Group_ID__c = testGroup.Id;
		testFunctionalQueue.Queue_ID__c = testQueue.Id;

		Test.startTest();
		update testFunctionalQueue;
		Test.stopTest();

		delete testFunctionalQueue;

		List<Group> correspondingGroups = [SELECT Id FROM Group WHERE Id = :testGroup.Id OR Id = :testQueue.Id];
		System.assertEquals(0, correspondingGroups.size());
	}

	@isTest
	static void onAfterUpdate_givenUpdatedFunctionalQueueAssociatedApplications_updatesExpectedSupportedObjects() {
		Group queueTest = TestUtility.createQueue('queue test');
		insert queueTest;

		Functional_Queue__c functionalQueue = createTestFunctionalQueue('Test FuncQueue');
		functionalQueue.Associated_Application__c = null;
		functionalQueue.Queue_ID__c = queueTest.Id;
		functionalQueue.RecordTypeID = Schema.SObjectType.Functional_Queue__c.getRecordTypeInfosByDeveloperName()
			.get('Functional_Queue_Default')
			.getRecordTypeId();
		insert functionalQueue;

		functionalQueue.Associated_Application__c = 'VIEWS';
		update functionalQueue;

		List<String> functionalQueueSupportedObjects = FunctionalQueueUtility.getFunctionalQueueSupportedObjectNamesByApp('VIEWS');

		Test.startTest();
		List<QueueSobject> actualSupportedQueueObjects = [SELECT Id, SobjectType FROM QueueSobject WHERE QueueId = :functionalQueue.Id];
		Test.stopTest();

		if (actualSupportedQueueObjects.size() > 0) {
			for (QueueSobject queueObject : actualSupportedQueueObjects) {
				System.assert(functionalQueueSupportedObjects.contains(queueObject.SobjectType));
			}
		}
	}

	private static Functional_Queue__c createTestFunctionalQueue(String functionalQueueName) {
		Functional_Queue__c testFunctionalQueue = new Functional_Queue__c();
		testFunctionalQueue.Associated_Application__c = 'VIEWS';
		testFunctionalQueue.Name = functionalQueueName;
		return testFunctionalQueue;
	}

	private static Group createTestGroup(String groupName, String groupType) {
		Group testGroup = new Group(Name = groupName, Type = groupType);
		insert testGroup;
		return testGroup;
	}

	private static User createStandardTestUser(String lastName) {
		Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
		User u = new User(
			Alias = lastName,
			Email = lastName + '@testorg.com',
			EmailEncodingKey = 'UTF-8',
			LastName = lastName,
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			ProfileId = p.Id,
			FederationIdentifier = lastName,
			TimeZoneSidKey = 'America/New_York',
			UserName = lastName +
				'@testorg.com' +
				UserInfo.getOrganizationId() +
				String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '')
		);
		insert u;
		return u;
	}

	@IsTest
	public static void testNcpsValidateUserCanEditMember() {
		PermissionSetGroup ncpsAdminGroup = [
			SELECT Id
			FROM PermissionSetGroup
			WHERE DeveloperName = 'NCPS_Admin_Group'
		];
		PermissionSetGroup psatAdmin = [
			SELECT Id
			FROM PermissionSetGroup
			WHERE DeveloperName = 'NCPS_PSAT_Admin'
		];

		System.runAs(new User(Id = UserInfo.getUserId())) {
			Test.calculatePermissionSetGroup(ncpsAdminGroup.Id);
			Test.calculatePermissionSetGroup(psatAdmin.Id);

			database.insert(
				new List<PermissionSetAssignment>{
					new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetGroupId = ncpsAdminGroup.Id),
					new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetGroupId = psatAdmin.Id)
				},
				false
			);
		}

		PermissionSet ncpsNationalPs = [SELECT Id, Name FROM PermissionSet WHERE Name = 'NCPS_National'];
		PermissionSet ncpsFqEdit = [SELECT Id, Name FROM PermissionSet WHERE Name = 'NCPS_Functional_Queue_Edit_Access'];
		PermissionSet ncpsAdmin = [SELECT Id, Name FROM PermissionSet WHERE Name = 'NCPS_Admin'];
		Group ncpsAllUsersGroup = [SELECT Id FROM Group WHERE DeveloperName = 'NCPS_All_users' AND Type = 'Regular'];

		List<Group> groups = new List<Group>();

		User u1;
		User u2;
		User adminUser;

		System.runAs(new User(Id = UserInfo.getUserId())) {
			for (Integer i = 0; i < 7; i++) {
				groups.add(new Group(Name = 'TestGroup' + i, Type = 'Regular'));
				groups.add(new Group(Name = 'TestQueue' + i, Type = 'Queue'));
			}

			insert groups;

			insert new GroupMember(UserOrGroupId = groups[0].Id, GroupId = groups[1].Id);

			u1 = createStandardTestUser('NCPSTU1');
			u2 = createStandardTestUser('NCPSTU2');
			adminUser = createStandardTestUser('NCPSTAdm');

			insert new List<PermissionSetAssignment>{
				new PermissionSetAssignment(AssigneeId = u1.Id, PermissionSetId = ncpsNationalPs.Id),
				new PermissionSetAssignment(AssigneeId = u1.Id, PermissionSetId = ncpsFqEdit.Id),
				new PermissionSetAssignment(AssigneeId = u2.Id, PermissionSetId = ncpsNationalPs.Id),
				new PermissionSetAssignment(AssigneeId = u2.Id, PermissionSetId = ncpsFqEdit.Id),
				new PermissionSetAssignment(AssigneeId = adminUser.Id, PermissionSetId = ncpsAdmin.Id),
				new PermissionSetAssignment(AssigneeId = adminUser.Id, PermissionSetId = ncpsFqEdit.Id)
			};
		}

		Id ncpsFqmRtId = Schema.SObjectType.Functional_Queue_Member__c.getRecordTypeInfosByDeveloperName()
			.get('NCPS_Alerts_Recalls_Functional_Queue_Member')
			.getRecordTypeId();
		Id ncpsNationalFqRtId = Schema.SObjectType.Functional_Queue__c.getRecordTypeInfosByDeveloperName()
			.get('NCPS_National_Functional_Queue')
			.getRecordTypeId();
		Id ncpsVISNFqRtId = Schema.SObjectType.Functional_Queue__c.getRecordTypeInfosByDeveloperName()
			.get('NCPS_VISN_Functional_Queue')
			.getRecordTypeId();
		Id ncpsL1FqRtId = Schema.SObjectType.Functional_Queue__c.getRecordTypeInfosByDeveloperName()
			.get('NCPS_Alerts_Recalls_Facility_Level_1_Functional_Queue')
			.getRecordTypeId();
		Id ncpsL12FqRtId = Schema.SObjectType.Functional_Queue__c.getRecordTypeInfosByDeveloperName()
			.get('NCPS_Alerts_Recalls_Facility_Level_1_2_Functional_Queue')
			.getRecordTypeId();
		Id ncpsL2FqRtId = Schema.SObjectType.Functional_Queue__c.getRecordTypeInfosByDeveloperName()
			.get('NCPS_Alerts_Recalls_Facility_Level_2_Functional_Queue')
			.getRecordTypeId();

		List<Functional_Queue__c> fqList = new List<Functional_Queue__c>{
			new Functional_Queue__c(
				Name = 'National',
				RecordTypeId = ncpsNationalFqRtId,
				NCPS_Category__c = 'National - RMD',
				Public_Group_ID__c = groups[0].Id,
				Queue_ID__c = groups[1].Id
			),
			new Functional_Queue__c(
				Name = 'VISN 1',
				RecordTypeId = ncpsVISNFqRtId,
				NCPS_Category__c = 'VISN BME',
				Public_Group_ID__c = groups[2].Id,
				Queue_ID__c = groups[3].Id
			),
			new Functional_Queue__c(
				Name = 'VISN 2',
				RecordTypeId = ncpsVISNFqRtId,
				Associated_Application__c = 'Alerts & Recalls - VISN',
				NCPS_Category__c = 'VISN BME',
				Public_Group_ID__c = groups[4].Id,
				Queue_ID__c = groups[5].Id
			),
			new Functional_Queue__c(
				Name = 'Facility L1 V1',
				RecordTypeId = ncpsL12FqRtId,
				Associated_Application__c = 'Alerts & Recalls - Facility Level 1 & 2',
				NCPS_Category__c = 'BME1',
				Public_Group_ID__c = groups[6].Id,
				Queue_ID__c = groups[7].Id
			),
			new Functional_Queue__c(
				Name = 'Facility L1 V2',
				RecordTypeId = ncpsL12FqRtId,
				Associated_Application__c = 'Alerts & Recalls - Facility Level 1 & 2',
				NCPS_Category__c = 'BME1',
				Public_Group_ID__c = groups[8].Id,
				Queue_ID__c = groups[9].Id
			),
			new Functional_Queue__c(
				Name = 'Facility L2 V1',
				RecordTypeId = ncpsL2FqRtId,
				Associated_Application__c = 'Alerts & Recalls - Facility Level 2',
				NCPS_Category__c = 'BME2',
				Public_Group_ID__c = groups[10].Id,
				Queue_ID__c = groups[11].Id
			),
			new Functional_Queue__c(
				Name = 'Facility L2 V2',
				RecordTypeId = ncpsL2FqRtId,
				Associated_Application__c = 'Alerts & Recalls - Facility Level 2',
				NCPS_Category__c = 'BME2',
				Public_Group_ID__c = groups[12].Id,
				Queue_ID__c = groups[13].Id
			)
		};

		List<Functional_Queue_Member__c> fqMembersUser1 = new List<Functional_Queue_Member__c>();
		List<Functional_Queue_Member__c> fqMembersUser2 = new List<Functional_Queue_Member__c>();

		System.runAs(new User(Id = UserInfo.getUserId())) {
			insert fqList;

			fqList[1].NCPS_Parent_Functional_Queue__c = fqList[0].Id; // visn 1 parent is national
			fqList[2].NCPS_Parent_Functional_Queue__c = fqList[0].Id; // visn 2 parent is national
			fqList[3].NCPS_Parent_Functional_Queue__c = fqList[1].Id; // L1 V1 parent is visn 1
			fqList[4].NCPS_Parent_Functional_Queue__c = fqList[2].Id; // L1 V2 parent is visn 2
			fqList[5].NCPS_Parent_Functional_Queue__c = fqList[3].Id; // L2 V1 parent is L1 V1
			fqList[6].NCPS_Parent_Functional_Queue__c = fqList[4].Id; // L2 V2 parent is L1 V2
			update fqList;

			List<Functional_Queue__Share> fqShares = new List<Functional_Queue__Share>();
			for (Functional_Queue__c fq : fqList) {
				fqShares.add(new Functional_Queue__Share(UserOrGroupId = u1.Id, RowCause = 'Manual', AccessLevel = 'Edit', ParentId = fq.Id));
				fqShares.add(new Functional_Queue__Share(UserOrGroupId = u2.Id, RowCause = 'Manual', AccessLevel = 'Edit', ParentId = fq.Id));
				fqShares.add(new Functional_Queue__Share(UserOrGroupId = adminUser.Id, RowCause = 'Manual', AccessLevel = 'Edit', ParentId = fq.Id));
			}
			insert fqShares;

			fqMembersUser1 = new List<Functional_Queue_Member__c>{
				new Functional_Queue_Member__c(RecordTypeId = ncpsFqmRtId, NCPS_User_Member__c = u1.Id, Functional_Queue__c = fqList[1].Id),
				new Functional_Queue_Member__c(RecordTypeId = ncpsFqmRtId, NCPS_User_Member__c = u1.Id, Functional_Queue__c = fqList[4].Id)
			};

			insert fqMembersUser1;

			fqMembersUser2 = new List<Functional_Queue_Member__c>{
				new Functional_Queue_Member__c(RecordTypeId = ncpsFqmRtId, NCPS_User_Member__c = u2.Id, Functional_Queue__c = fqList[1].Id),
				new Functional_Queue_Member__c(RecordTypeId = ncpsFqmRtId, NCPS_User_Member__c = u2.Id, Functional_Queue__c = fqList[3].Id),
				new Functional_Queue_Member__c(RecordTypeId = ncpsFqmRtId, NCPS_User_Member__c = u2.Id, Functional_Queue__c = fqList[4].Id),
				new Functional_Queue_Member__c(RecordTypeId = ncpsFqmRtId, NCPS_User_Member__c = u2.Id, Functional_Queue__c = fqList[5].Id),
				new Functional_Queue_Member__c(RecordTypeId = ncpsFqmRtId, NCPS_User_Member__c = u2.Id, Functional_Queue__c = fqList[6].Id)
			};
		}

		Boolean hasError = false;

		System.runAs(u1) {
			try {
				insert fqMembersUser2;
			} catch (Exception e) {
				hasError = true;
			}

			system.assertEquals(false, hasError, 'User 1 created FQ members for User 2 sucessfully in allowed queues');
		}

		String oldGroupId = fqList[1].Public_Group_ID__c;
		fqList[6].Public_Group_ID__c = null;
		update fqList[6];

		System.runAs(u1) {
			try {
				fqList[6].Public_Group_ID__c = oldGroupId;
				update fqList[6];
			} catch (Exception e) {
				hasError = true;
			}

			system.assertEquals(false, hasError, 'User 1 edit allowed when public group id is being set');

			try {
				delete fqMembersUser2;
			} catch (Exception e) {
				hasError = true;
			}

			system.assertEquals(false, hasError, 'User 1 deleted FQ members for User 2 sucessfully in allowed queues');

			String errorMessage;

			try {
				insert new Functional_Queue_Member__c(RecordTypeId = ncpsFqmRtId, NCPS_User_Member__c = u2.Id, Functional_Queue__c = fqList[2].Id);
			} catch (Exception e) {
				hasError = true;
				errorMessage = e.getMessage();
			}
			system.assertEquals(
				true,
				errorMessage.contains('You do not have the necessary permissions to'),
				'User 1 encountered error adding to an unallowed queue'
			);
		}

		List<Functional_Queue_Member__c> fqMembersUser2All = new List<Functional_Queue_Member__c>{
			new Functional_Queue_Member__c(RecordTypeId = ncpsFqmRtId, NCPS_User_Member__c = u2.Id, Functional_Queue__c = fqList[0].Id),
			new Functional_Queue_Member__c(RecordTypeId = ncpsFqmRtId, NCPS_User_Member__c = u2.Id, Functional_Queue__c = fqList[1].Id),
			new Functional_Queue_Member__c(RecordTypeId = ncpsFqmRtId, NCPS_User_Member__c = u2.Id, Functional_Queue__c = fqList[2].Id),
			new Functional_Queue_Member__c(RecordTypeId = ncpsFqmRtId, NCPS_User_Member__c = u2.Id, Functional_Queue__c = fqList[3].Id),
			new Functional_Queue_Member__c(RecordTypeId = ncpsFqmRtId, NCPS_User_Member__c = u2.Id, Functional_Queue__c = fqList[4].Id),
			new Functional_Queue_Member__c(RecordTypeId = ncpsFqmRtId, NCPS_User_Member__c = u2.Id, Functional_Queue__c = fqList[5].Id),
			new Functional_Queue_Member__c(RecordTypeId = ncpsFqmRtId, NCPS_User_Member__c = u2.Id, Functional_Queue__c = fqList[6].Id)
		};

		System.runAs(adminUser) {
			hasError = false;

			try {
				insert fqMembersUser2All;
			} catch (Exception e) {
				hasError = true;
			}

			system.assertEquals(false, hasError, 'Admin created FQ members for User 2 sucessfully in all queues');
		}

	}
}