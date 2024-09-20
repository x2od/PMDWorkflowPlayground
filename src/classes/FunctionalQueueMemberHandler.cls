/**
 * @description       :
 * @author            :
 * @group             :
 * @last modified on  : 10-21-2021
 * @last modified by  :
 **/
public without sharing class FunctionalQueueMemberHandler { //NOPMD
	public void OnBeforeInsert(List<Functional_Queue_Member__c> newFunctionalQueueMembers) {
		Set<Id> relatedFunctionalQueueIds = getRelatedFunctionalQueueIds(newFunctionalQueueMembers);
		FunctionalQueueUtility.createQueueGroupIfAssociatedFunctionalQueueIsNonExistent(relatedFunctionalQueueIds);

		Map<Id, Set<Id>> functionalQueueToContactsMap = getFunctionalQueueToContactsMap(relatedFunctionalQueueIds);
		Map<Id, Set<Id>> functionalQueueToUsersMap = getFunctionalQueueToUsersMap(relatedFunctionalQueueIds);
		Id ncpsRecordTypeId = Schema.SObjectType.Functional_Queue_Member__c.getRecordTypeInfosByDeveloperName()
			.get('NCPS_Alerts_Recalls_Functional_Queue_Member')
			.getRecordTypeId();
		for (Functional_Queue_Member__c newMember : newFunctionalQueueMembers) {
			if (newMember.RecordTypeId == ncpsRecordTypeId) {
				newMember.NCPS_Pending_Member__c = true;

				if (memberIsDuplicateUser(functionalQueueToUsersMap, newMember)) {
					newMember.addError('This user is already a member of this functional queue.');
				}

				// For NCPS PSAT only, checks that user has necessary privileges to add new FQM
				if (!ncpsPsatCanCreate(newMember)) {
					newMember.addError('You do not have the necessary privileges to add new functional queue members.');
				}
			} else {
				if (memberIsDuplicate(functionalQueueToContactsMap, newMember)) {
					newMember.addError('This contact is already a member of this functional queue.');
				}
			}
		}
	}

	public void OnAfterInsert(List<Functional_Queue_Member__c> newFunctionalQueueMembers) {
		Set<Id> newMemberIds = new Set<Id>();
		for (Functional_Queue_Member__c newMember : newFunctionalQueueMembers) {
			newMemberIds.add(newMember.Id);
		}
		addNewMembersToCorrespondingGroups(newMemberIds);
	}

	public void OnBeforeDelete(List<Functional_Queue_Member__c> deletedFunctionalQueueMembers) {
		Set<Id> groupMemberIdsToDelete = getGroupMemberIdsToDelete(deletedFunctionalQueueMembers);
		deleteFunctionalQueueGroupMembers(groupMemberIdsToDelete);

		Id ncpsRecordTypeId = Schema.SObjectType.Functional_Queue_Member__c.getRecordTypeInfosByDeveloperName()
			.get('NCPS_Alerts_Recalls_Functional_Queue_Member')
			.getRecordTypeId();
		for (Functional_Queue_Member__c deletedMember : deletedFunctionalQueueMembers) {
			if (deletedMember.RecordTypeId == ncpsRecordTypeId) {
				// For NCPS PSAT only, checks that user has necessary privileges to add new FQM
				if (!ncpsPsatCanCreate(deletedMember)) {
					deletedMember.addError('You do not have the necessary privileges to remove functional queue members.');
				}
			}
		}
	}

	/*****************************************************************************
	 *  Returns a set of any Functional Queue IDs related to the newly created
	 *  functional queue members
	 ****************************************************************************/
	private Set<Id> getRelatedFunctionalQueueIds(List<Functional_Queue_Member__c> functionalQueueMembers) {
		Set<Id> functionalQueueIds = new Set<Id>();
		for (Functional_Queue_Member__c member : functionalQueueMembers) {
			functionalQueueIds.add(member.Functional_Queue__c);
		}
		return functionalQueueIds;
	}

	/*****************************************************************************
	 *  Returns a map that correlates functional queues to their respective
	 *  existing member contact IDs in order to make it easy to check for dupes
	 ****************************************************************************/
	private Map<Id, Set<Id>> getFunctionalQueueToContactsMap(Set<Id> functionalQueueIds) {
		List<Functional_Queue_Member__c> existingFunctionalQueueMembers = [
			SELECT Contact_Member__c, Functional_Queue__c
			FROM Functional_Queue_Member__c
			WHERE Functional_Queue__c IN :functionalQueueIds
		];
		Map<Id, Set<Id>> functionalQueueToContactsMap = new Map<Id, Set<Id>>();
		for (Functional_Queue_Member__c existingMember : existingFunctionalQueueMembers) {
			if (functionalQueueToContactsMap.containsKey(existingMember.Functional_Queue__c)) {
				functionalQueueToContactsMap.get(existingMember.Functional_Queue__c).add(existingMember.Contact_Member__c);
			} else {
				functionalQueueToContactsMap.put(existingMember.Functional_Queue__c, new Set<Id>{ existingMember.Contact_Member__c });
			}
		}

		return functionalQueueToContactsMap;
	}

	/*****************************************************************************
	 *  Returns a map that correlates functional queues to their respective
	 *  existing member user IDs in order to make it easy to check for dupes
	 ****************************************************************************/
	private Map<Id, Set<Id>> getFunctionalQueueToUsersMap(Set<Id> functionalQueueIds) {
		List<Functional_Queue_Member__c> existingFunctionalQueueMembers = [
			SELECT NCPS_User_Member__c, Functional_Queue__c
			FROM Functional_Queue_Member__c
			WHERE Functional_Queue__c IN :functionalQueueIds
		];
		Map<Id, Set<Id>> functionalQueueToUsersMap = new Map<Id, Set<Id>>();
		for (Functional_Queue_Member__c existingMember : existingFunctionalQueueMembers) {
			if (functionalQueueToUsersMap.containsKey(existingMember.Functional_Queue__c)) {
				functionalQueueToUsersMap.get(existingMember.Functional_Queue__c).add(existingMember.NCPS_User_Member__c);
			} else {
				functionalQueueToUsersMap.put(existingMember.Functional_Queue__c, new Set<Id>{ existingMember.NCPS_User_Member__c });
			}
		}

		return functionalQueueToUsersMap;
	}

	/*****************************************************************************
	 *  Checks the functionalQueueToContactsMap if the new functional queue
	 *  member contact matches an existing contact on the same functional queue
	 ****************************************************************************/
	private Boolean memberIsDuplicate(Map<Id, Set<Id>> functionalQueueToContactsMap, Functional_Queue_Member__c functionalQueueMember) {
		if (functionalQueueToContactsMap.containsKey(functionalQueueMember.Functional_Queue__c)) {
			return functionalQueueToContactsMap.get(functionalQueueMember.Functional_Queue__c).contains(functionalQueueMember.Contact_Member__c);
		}
		return false;
	}

	/*****************************************************************************
	 *  Checks the functionalQueueToUsersMap if the new functional queue
	 *  member user matches an existing user on the same functional queue
	 ****************************************************************************/
	private Boolean memberIsDuplicateUser(Map<Id, Set<Id>> functionalQueueToUsersMap, Functional_Queue_Member__c functionalQueueMember) {
		if (functionalQueueToUsersMap.containsKey(functionalQueueMember.Functional_Queue__c)) {
			return functionalQueueToUsersMap.get(functionalQueueMember.Functional_Queue__c).contains(functionalQueueMember.NCPS_User_Member__c);
		}
		return false;
	}

	/*****************************************************************************
	 *  Creates the corresponding group members for each of the new functional
	 *  queue member IDs
	 ****************************************************************************/
	@future
	public static void addNewMembersToCorrespondingGroups(Set<Id> newFunctionalQueueMemberIds) {
		List<Functional_Queue_Member__c> newFunctionalQueueMembers = [
			SELECT
				Functional_Queue__c,
				Functional_Queue__r.Queue_ID__c,
				Functional_Queue__r.Public_Group_ID__c,
				Contact_Member__c,
				Contact_Member__r.User_Id__c,
				RecordType.DeveloperName,
				NCPS_User_Member__c
			FROM Functional_Queue_Member__c
			WHERE Id IN :newFunctionalQueueMemberIds
		];
		List<GroupMember> newMembersToInsert = new List<GroupMember>();
		for (Functional_Queue_Member__c newQueueMember : newFunctionalQueueMembers) {
			if (newQueueMember.RecordType.DeveloperName == 'NCPS_Alerts_Recalls_Functional_Queue_Member') {
				newMembersToInsert.add(
					FunctionalQueueUtility.createGroupMemberByGroupIdAndUserOrGroupId(
						newQueueMember.Functional_Queue__r.Public_Group_ID__c,
						newQueueMember.NCPS_User_Member__c
					)
				);
			} else {
				newMembersToInsert.add(
					FunctionalQueueUtility.createGroupMemberByGroupIdAndUserOrGroupId(
						newQueueMember.Functional_Queue__r.Public_Group_ID__c,
						newQueueMember.Contact_Member__r.User_ID__c
					)
				);
			}
		}

		insert newMembersToInsert;
	}

	/*****************************************************************************
	 *  Returns a set of IDs that represent the group members that correspond
	 *  to deleted Functional Queue Members
	 *  -  Query for functional queue member merge fields to get corresponding
	 *       group and user IDs
	 *  -  Query for group members that belong to the relevant public groups
	 *  -  Loop through deleted functional queue members to match them to
	 *     corresponding group members
	 ****************************************************************************/
	private Set<Id> getGroupMemberIdsToDelete(List<Functional_Queue_Member__c> deletedFunctionalQueueMembers) {
		Set<Id> deletedMemberIds = new Set<Id>();
		for (Functional_Queue_Member__c deletedMember : deletedFunctionalQueueMembers) {
			deletedMemberIds.add(deletedMember.Id);
		}
		List<Functional_Queue_Member__c> membersToRemove = [
			SELECT Functional_Queue__r.Public_Group_ID__c, Contact_Member__r.User_Id__c, NCPS_User_Member__c
			FROM Functional_Queue_Member__c
			WHERE Id IN :deletedMemberIds
		];

		Set<Id> relatedGroupIds = new Set<Id>();
		for (Functional_Queue_Member__c deletedMember : membersToRemove) {
			relatedGroupIds.add(deletedMember.Functional_Queue__r.Public_Group_ID__c);
		}
		List<GroupMember> relatedGroupMembers = [SELECT UserOrGroupId, GroupId FROM GroupMember WHERE GroupId IN :relatedGroupIds];

		Set<Id> groupMemberIdsToDelete = new Set<Id>();
		for (Functional_Queue_Member__c deletedMember : membersToRemove) {
			for (GroupMember relatedGroupMember : relatedGroupMembers) {
				if (
					(relatedGroupMember.UserOrGroupId == deletedMember.Contact_Member__r.User_Id__c ||
					relatedGroupMember.UserOrGroupId == deletedMember.NCPS_User_Member__c) &&
					relatedGroupMember.GroupId == deletedMember.Functional_Queue__r.Public_Group_ID__c
				) {
					groupMemberIdsToDelete.add(relatedGroupMember.Id);
				}
			}
		}
		return groupMemberIdsToDelete;
	}

	@future
	public static void deleteFunctionalQueueGroupMembers(Set<Id> groupMemberIds) {
		List<GroupMember> groupMembersToDelete = [SELECT Id FROM GroupMember WHERE Id IN :groupMemberIds];
		delete groupMembersToDelete;
	}

	// For NCPS PSAT only, checks that user has necessary privileges to add new FQM
	private Boolean ncpsPsatCanCreate(Functional_Queue_Member__c newMember) {
		List<NCPS_Create_Functional_Queue_Member.CanCreateRequest> requests = new List<NCPS_Create_Functional_Queue_Member.CanCreateRequest>();
		NCPS_Create_Functional_Queue_Member.CanCreateRequest request = new NCPS_Create_Functional_Queue_Member.CanCreateRequest();
		request.userId = userinfo.getUserId();
		request.functionalQueueId = newMember.Functional_Queue__c;
		requests.add(request);
		return NCPS_Create_Functional_Queue_Member.canCreateFunctionalQueueMember(requests)[0];
	}
}