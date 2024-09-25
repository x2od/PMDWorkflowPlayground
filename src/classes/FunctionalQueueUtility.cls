/**
 * @description       :
 * @author            :
 * @group             :
 * @last modified on  : 11-09-2021
 * @last modified by  :
 **/
public without sharing class FunctionalQueueUtility {
	/*****************************************************************************
	 *  Creates the corresponding Queue and Public Group for the functional
	 *  queue record when the first member of the functional queue is added and
	 *  there are no existing corresponding groups associated
	 ****************************************************************************/
	public static void createQueueGroupIfAssociatedFunctionalQueueIsNonExistent(Set<Id> relatedFunctionalQueueIds) {
		Map<Id, Functional_Queue__c> relatedFunctionalQueues = getFunctionalQueuesMapByIds(relatedFunctionalQueueIds);
		for (Functional_Queue__c functionalQueue : relatedFunctionalQueues.values()) {
			if (functionalQueueOrGroupNonExistent(functionalQueue)) {
				createFunctionalQueueGroups(functionalQueue);
			}
		}
	}

	/*****************************************************************************
	 *  Creates the corresponding Queue and Public Group for the functional
	 *  queue record
	 ****************************************************************************/
	private static void createFunctionalQueueGroups(Functional_Queue__c functionalQueue) {
		String groupName = formatGroupName(functionalQueue.Name);
		Group correspondingGroup = new Group(Name = groupName, Type = 'Regular');
		Group correspondingQueue = new Group(Name = groupName, Type = 'Queue');
		List<Group> correspondingGroups = new List<Group>{ correspondingGroup, correspondingQueue };
		insert correspondingGroups;
		functionalQueue.Public_Group_ID__c = correspondingGroups[0].Id;
		functionalQueue.Queue_ID__c = correspondingGroups[1].Id;
		update functionalQueue;

		addSupportedObjectsToQueueIfAssociatedApplicationGiven(functionalQueue.Associated_Application__c, functionalQueue.Queue_ID__c);
		addPublicGroupToQueue(functionalQueue.Public_Group_ID__c, functionalQueue.Queue_ID__c);
	}

	private static void addSupportedObjectsToQueueIfAssociatedApplicationGiven(String associatedApplicationName, String queueId) {
		if (String.isNotBlank(associatedApplicationName)) {
			String serializedSupportedQueueObjects = getSerializedFunctionalQueueSupportedObjectNamesByApp(associatedApplicationName, queueId);
			addSerializedSupportedObjectsToQueue(serializedSupportedQueueObjects);
		}
	}

	private static String getSerializedFunctionalQueueSupportedObjectNamesByApp(String associatedApplicationName, String queueId) {
		List<String> supportedObjectNamesByApp = getFunctionalQueueSupportedObjectNamesByApp(associatedApplicationName);
		List<QueueSobject> supportedQueueSobjects = buildSupportedQueueSObjectsBySupportedObjectsAndQueueId(supportedObjectNamesByApp, queueId);
		return JSON.serialize(supportedQueueSobjects);
	}

	private static Boolean functionalQueueOrGroupNonExistent(Functional_Queue__c functionalQueue) {
		return (functionalQueue.Queue_ID__c == null &&
		functionalQueue.Public_Group_ID__c == null &&
		functionalQueue.Number_of_Members__c == 0 &&
		functionalQueue.Number_of_Sub_Queues__c == 0);
	}

	/*****************************************************************************
	 *  Formats the functional queue name to pass Group.Name validations
	 ****************************************************************************/
	private static String formatGroupName(String functionalQueueName) {
		if (functionalQueueName.length() > 40) {
			functionalQueueName = functionalQueueName.substring(0, 39);
		}
		return functionalQueueName;
	}

	/*****************************************************************************
	 *  Returns Functional Queues specified in the set of IDs
	 ****************************************************************************/
	public static Map<Id, Functional_Queue__c> getFunctionalQueuesMapByIds(Set<Id> functionalQueueIds) {
		return new Map<Id, Functional_Queue__c>(
			[
				SELECT Name, Queue_ID__c, Public_Group_ID__c, Number_of_Members__c, Number_of_Sub_Queues__c, Associated_Application__c
				FROM Functional_Queue__c
				WHERE Id IN :functionalQueueIds
			]
		);
	}

	public static List<Sub_Functional_Queue__c> getSubFunctionalQueuesByParentFunctionalQueueIds(Set<Id> functionalQueueIds) {
		return [
			SELECT
				Id,
				Parent_Functional_Queue__c,
				Parent_Functional_Queue__r.Public_Group_ID__c,
				Parent_Functional_Queue__r.Queue_ID__c,
				Sub_Functional_Queue__r.Public_Group_ID__c,
				Sub_Functional_Queue__r.Queue_ID__c,
				Sub_Functional_Queue__r.Id,
				Sub_Functional_Queue__r.Name,
				Sub_Functional_Queue__r.Number_of_Members__c,
				Sub_Functional_Queue__r.Number_of_Sub_Queues__c,
				Sub_Functional_Queue__r.Related_Office__c
			FROM Sub_Functional_Queue__c
			WHERE Parent_Functional_Queue__c IN :functionalQueueIds
		];
	}

	public static List<Functional_Queue__c> getFunctionalQueuesByIds(Set<Id> functionalQueueIds) {
		return [
			SELECT
				Name,
				Queue_ID__c,
				Public_Group_ID__c,
				Number_of_Members__c,
				Number_of_Sub_Queues__c,
				Related_Office__c,
				(
					SELECT
						Sub_Functional_Queue__c,
						Sub_Functional_Queue__r.Id,
						Sub_Functional_Queue__r.Public_Group_ID__c,
						Sub_Functional_Queue__r.Queue_ID__c,
						Sub_Functional_Queue__r.Name,
						Sub_Functional_Queue__r.Number_of_Members__c,
						Sub_Functional_Queue__r.Number_of_Sub_Queues__c,
						Sub_Functional_Queue__r.Related_Office__c
					FROM Sub_Functional_Queues__r
				)
			FROM Functional_Queue__c
			WHERE Id IN :functionalQueueIds
		];
	}

	private static List<QueueSobject> buildSupportedQueueSObjectsBySupportedObjectsAndQueueId(List<String> supportedObjects, Id queueId) {
		List<QueueSobject> supportedQueueSobjects = new List<QueueSobject>();
		for (String sObjectName : supportedObjects) {
			supportedQueueSobjects.add(buildQueueSobjectByQueueIdAndSupportedObjectName(sObjectName, queueId));
		}

		return supportedQueueSobjects;
	}

	/*****************************************************************************
	 *  Adds the necessary supported objects to the queue
	 ****************************************************************************/
	@Future
	public static void addSerializedSupportedObjectsToQueue(String serializedSupportedObjects) {
		List<QueueSobject> supportedObjects = (List<QueueSobject>) JSON.deserialize(serializedSupportedObjects, List<QueueSobject>.class);
		upsert supportedObjects;
	}

	@Future
	public static void deleteSerializedSupportedQueueObjects(String serializedSupportedObjects) {
		List<QueueSobject> supportedObjects = (List<QueueSobject>) JSON.deserialize(serializedSupportedObjects, List<QueueSobject>.class);
		delete supportedObjects;
	}

	/*****************************************************************************
	 *  Adds corresponding public group as groupmember to the corresponding queue
	 ****************************************************************************/
	@Future
	private static void addPublicGroupToQueue(Id groupId, Id queueId) {
		insert new GroupMember(GroupId = queueId, UserOrGroupId = groupId);
	}

	public static QueueSobject buildQueueSobjectByQueueIdAndSupportedObjectName(String supportedObjectName, Id queueId) {
		return new QueueSobject(QueueId = queueId, SobjectType = supportedObjectName);
	}

	/*****************************************************************************
	 *  Builds the GroupMember record for a given Functional Queue Member
	 ****************************************************************************/
	public static GroupMember createGroupMemberByGroupIdAndUserOrGroupId(Id groupId, Id userOrGroupId) {
		GroupMember functionalQueueMember = new GroupMember();
		functionalQueueMember.GroupId = groupId;
		functionalQueueMember.UserOrGroupId = userOrGroupId;
		return functionalQueueMember;
	}

	public static List<GroupMember> getGroupMembersByGroupIds(Set<Id> groupIds) {
		return [
			SELECT Id, UserOrGroupId, GroupId
			FROM GroupMember
			WHERE GroupId IN :groupIds
		];
	}

	public static List<Sub_Functional_Queue__c> getSubFunctionalQueuesByIds(Set<Id> subFunctionalQueueIds) {
		return [
			SELECT
				Id,
				Parent_Functional_Queue__r.Public_Group_ID__c,
				Parent_Functional_Queue__r.Queue_ID__c,
				Sub_Functional_Queue__r.Public_Group_ID__c,
				Sub_Functional_Queue__r.Queue_ID__c
			FROM Sub_Functional_Queue__c
			WHERE Id IN :subFunctionalQueueIds
		];
	}

	public static List<String> getFunctionalQueueSupportedObjectNamesByApp(String associatedApplication) {
		List<FunctionalQueue_Supported_Objects_By_App__mdt> functionalQueueSupportedObjectsAppSettings = getFunctionalQueueSupportedObjectsCustomMetaDataByAppNames(
			new Set<String>{ associatedApplication }
		);
		List<String> supportedObjects = new List<String>();
		if (functionalQueueSupportedObjectsAppSettings != null && functionalQueueSupportedObjectsAppSettings.size() > 0) {
			supportedObjects = functionalQueueSupportedObjectsAppSettings[0].Supported_Objects__c.split(',');
		}

		return supportedObjects;
	}

	public static List<FunctionalQueue_Supported_Objects_By_App__mdt> getFunctionalQueueSupportedObjectsCustomMetaDataByAppNames(
		Set<String> associatedApplications
	) {
		return [
			SELECT Id, Application_Name__c, Supported_Objects__c
			FROM FunctionalQueue_Supported_Objects_By_App__mdt
			WHERE Application_Name__c IN :associatedApplications
		];
	}

	public static List<QueueSobject> getQueueSObjectsByQueueIds(Set<Id> queueIds) {
		return [
			SELECT Id, SobjectType, QueueId
			FROM QueueSobject
			WHERE QueueId IN :queueIds
		];
	}

	public static List<Functional_Queue__c> getFunctionalQueuesByRecordTypeId(List<Functional_Queue__c> functionalQueues, Id recordTypeId) {
		List<Functional_Queue__c> functionalQueuesOfGivenRecordType = new List<Functional_Queue__c>();
		for (Functional_Queue__c fq : functionalQueues) {
			if (fq.RecordTypeId == recordTypeId) {
				functionalQueuesOfGivenRecordType.add(fq);
			}
		}
		return functionalQueuesOfGivenRecordType;
	}

	public static void deleteSharingRulesGivenFunctionalQueues(List<Functional_Queue__c> functionalQueues) {
		Set<Id> functionalQueueIds = new Set<Id>();
		for (Functional_Queue__c fq : functionalQueues) {
			functionalQueueIds.add(fq.Id);
		}

		List<Functional_Queue__Share> sharingRulesToDelete = [
			SELECT Id
			FROM Functional_Queue__Share
			WHERE ParentId IN :functionalQueueIds AND RowCause = 'Manual'
		];
		delete sharingRulesToDelete;
	}

	public static Map<Id, Account> getRelatedOfficeMap(List<Functional_Queue__c> functionalQueues) {
		Set<Id> accountIds = new Set<Id>();
		for (Functional_Queue__c fq : functionalQueues) {
			if (fq.Related_Office__c != null) {
				accountIds.add(fq.Related_Office__c);
			}
		}
		return new Map<Id, Account>([SELECT Id, CF_Group_ID__c FROM Account WHERE Id IN :accountIds]);
	}
}