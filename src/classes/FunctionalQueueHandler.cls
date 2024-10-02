/**
 * @description       :
 * @author            :
 * @group             :
 * @last modified on  : 10-27-2023
 * @last modified by  :
 **/
public class FunctionalQueueHandler {
	// Staged Properties
	List<FunctionalQueue_Supported_Objects_By_App__mdt> functionalQueueSupportedObjectsSettings;

	// DML Properties
	List<QueueSobject> queueSObjectsToDelete = new List<QueueSobject>();
	List<QueueSobject> queueSobjectsToSave = new List<QueueSobject>();
	List<Functional_Queue__share> sharingRulesToSave = new List<Functional_Queue__share>();

	public void onAfterInsert(List<Functional_Queue__c> insertedFunctionalQueues) {
		applyAfterInsertLogic(insertedFunctionalQueues);
		performDMLOperationsForAfterInsert();
		ncpsValidateUserCanEditFq(insertedFunctionalQueues, 'insert');
	}

	public void onAfterDelete(List<Functional_Queue__c> deletedFunctionalQueues) {
		deleteFunctionalQueueGroups(deletedFunctionalQueues);
	}

	public void deleteFunctionalQueueGroups(List<Functional_Queue__c> deletedFunctionalQueues) {
		Set<Id> groupIdsToDelete = new Set<Id>();
		for (Functional_Queue__c deletedFunctionalQueue : deletedFunctionalQueues) {
			if (deletedFunctionalQueue.Public_Group_ID__c != null) {
				groupIdsToDelete.add(deletedFunctionalQueue.Public_Group_ID__c);
			}
			if (deletedFunctionalQueue.Queue_ID__c != null) {
				groupIdsToDelete.add(deletedFunctionalQueue.Queue_ID__c);
			}
		}

		List<Group> groupsToDelete = [SELECT Id FROM Group WHERE Id IN :groupIdsToDelete]; //NOSONAR
		delete groupsToDelete; //NOSONAR
	}

	public void onAfterUpdate(List<Functional_Queue__c> updatedFunctionalQueues, List<Functional_Queue__c> oldFunctionalQueues) {
		stageRelatedPropertiesForAfterUpdate(updatedFunctionalQueues, oldFunctionalQueues);
		for (Functional_Queue__c functionalQueue : updatedFunctionalQueues) {
			applyAfterUpdateLogic(oldFunctionalQueues, functionalQueue);
		}

		performDMLOperationsForAfterUpdate();
	}

	public void onBeforeUpdate(List<Functional_Queue__c> updatedFunctionalQueues, Map<Id, Functional_Queue__c> oldFunctionalQueueMap) {
		ncpsValidateUserCanEditFq(updatedFunctionalQueues, oldFunctionalQueueMap, 'update');
	}
	public void onBeforeDelete(List<Functional_Queue__c> updatedFunctionalQueues) {
		ncpsValidateUserCanEditFq(updatedFunctionalQueues, 'delete');
	}

	private void stageRelatedPropertiesForAfterUpdate(
		List<Functional_Queue__c> updatedFunctionalQueues,
		List<Functional_Queue__c> oldFunctionalQueues
	) {
		stageFunctionalQueueSupportedObjectsProperties(updatedFunctionalQueues, oldFunctionalQueues);
	}

	private void applyAfterUpdateLogic(List<Functional_Queue__c> oldFunctionalQueues, Functional_Queue__c functionalQueue) {
		updateFunctionalQueueWithUpdatedApplicationSupportedObjects(functionalQueue);
	}

	private void performDMLOperationsForAfterUpdate() {
		FunctionalQueueUtility.addSerializedSupportedObjectsToQueue(JSON.serialize(queueSobjectsToSave));
		if (queueSObjectsToDelete != null && !queueSObjectsToDelete.isEmpty()) {
			FunctionalQueueUtility.deleteSerializedSupportedQueueObjects(JSON.serialize(queueSObjectsToDelete));
		}
		if (!sharingRulesToSave.isEmpty()) {
			insert sharingRulesToSave; //NOSONAR
		}
	}

	private void applyAfterInsertLogic(List<Functional_Queue__c> insertedFunctionalQueues) {
	}

	private void performDMLOperationsForAfterInsert() {
		if (!sharingRulesToSave.isEmpty()) {
			insert sharingRulesToSave; //NOSONAR
		}
	}

	private void stageFunctionalQueueSupportedObjectsProperties(
		List<Functional_Queue__c> updatedFunctionalQueues,
		List<Functional_Queue__c> oldFunctionalQueues
	) {
		Set<Id> updatedApplicationNameQueueIds = new Set<Id>();
		Set<String> updatedFunctionalQueueApplicationNames = new Set<String>();
		for (Functional_Queue__c updatedFunctionalQueue : updatedFunctionalQueues) {
			for (Functional_Queue__c oldFunctionalQueue : oldFunctionalQueues) {
				if (functionalQueueUpdateRequiresSupportedObjectsUpdate(updatedFunctionalQueue, oldFunctionalQueue)) {
					updatedApplicationNameQueueIds.add(updatedFunctionalQueue.Queue_ID__c);
					updatedFunctionalQueueApplicationNames.add(updatedFunctionalQueue.Associated_Application__c);
				}
			}
		}

		queueSObjectsToDelete = FunctionalQueueUtility.getQueueSObjectsByQueueIds(updatedApplicationNameQueueIds);
		functionalQueueSupportedObjectsSettings = FunctionalQueueUtility.getFunctionalQueueSupportedObjectsCustomMetaDataByAppNames(
			updatedFunctionalQueueApplicationNames
		);
	}

	private Boolean functionalQueueUpdateRequiresSupportedObjectsUpdate(
		Functional_Queue__c updatedFunctionalQueue,
		Functional_Queue__c oldFunctionalQueue
	) {
		return (functionalQueueAssociatedQueueIdIsUpdated(updatedFunctionalQueue.Queue_ID__c, oldFunctionalQueue.Queue_ID__c) ||
		functionalQueueAssociatedApplicationIsUpdated(updatedFunctionalQueue, oldFunctionalQueue.Associated_Application__c));
	}

	private Boolean functionalQueueAssociatedQueueIdIsUpdated(String updatedAssociatedQueueId, String oldAssociatedQueueId) {
		return (updatedAssociatedQueueId != oldAssociatedQueueId);
	}

	private Boolean functionalQueueAssociatedApplicationIsUpdated(Functional_Queue__c updatedFunctionalQueue, String oldAssociatedApplicationName) {
		return (updatedFunctionalQueue.Associated_Application__c != oldAssociatedApplicationName &&
		String.isNotBlank(updatedFunctionalQueue.Queue_ID__c));
	}

	private void updateFunctionalQueueWithUpdatedApplicationSupportedObjects(Functional_Queue__c functionalQueue) {
		for (FunctionalQueue_Supported_Objects_By_App__mdt functionalQueueSupportedObjectsSetting : functionalQueueSupportedObjectsSettings) {
			if (functionalQueue.Associated_Application__c == functionalQueueSupportedObjectsSetting.Application_Name__c) {
				List<String> applicationSupportedObjects = functionalQueueSupportedObjectsSetting.Supported_Objects__c.split(',');
				for (String supportedObjectType : applicationSupportedObjects) {
					queueSobjectsToSave.add(
						FunctionalQueueUtility.buildQueueSobjectByQueueIdAndSupportedObjectName(supportedObjectType, functionalQueue.Queue_ID__c)
					);
				}
			}
		}
	}

	private void buildSharingRulesForFunctionalQueues(List<Functional_Queue__c> functionalQueues) {
		Map<Id, Account> accountMap = FunctionalQueueUtility.getRelatedOfficeMap(functionalQueues);

		for (Functional_Queue__c fq : functionalQueues) {
			// build sharing rules by record type
		}
	}

	public static void ncpsValidateUserCanEditFq(List<Functional_Queue__c> newFqList, String op) {
		ncpsValidateUserCanEditFq(newFqList, new Map<Id, Functional_Queue__c>(), op);
	}

	public static void ncpsValidateUserCanEditFq(List<Functional_Queue__c> newFqList, Map<Id, Functional_Queue__c> oldFqMap, String op) {
		Id adminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;

		List<Id> fqsToClearPendingMembers = new List<Id>();

		Map<String, Schema.RecordTypeInfo> fqRtMap = Schema.SObjectType.Functional_Queue__c.getRecordTypeInfosByDeveloperName();
		Map<Id, String> ncpsFqRtIdMap = new Map<Id, String>{
			fqRtMap.get('NCPS_National_Functional_Queue').getRecordTypeId() => 'National',
			fqRtMap.get('NCPS_VISN_Functional_Queue').getRecordTypeId() => 'VISN',
			fqRtMap.get('NCPS_Alerts_Recalls_Facility_Level_1_Functional_Queue').getRecordTypeId() => 'Facility 1',
			fqRtMap.get('NCPS_Alerts_Recalls_Facility_Level_1_2_Functional_Queue').getRecordTypeId() => 'Facility 1/2',
			fqRtMap.get('NCPS_Alerts_Recalls_Facility_Level_2_Functional_Queue').getRecordTypeId() => 'Facility 2'
		};
		Boolean ncpsAdminOrSuperuser = FeatureManagement.checkPermission('NCPS_Admin_User') || FeatureManagement.checkPermission('NCPS_Super_User');

		if (!ncpsAdminOrSuperuser && UserInfo.getProfileId() != adminProfileId) {
			Id ncpsFqmRtId = Schema.SObjectType.Functional_Queue_Member__c.getRecordTypeInfosByDeveloperName()
				.get('NCPS_Alerts_Recalls_Functional_Queue_Member')
				.getRecordTypeId();

			List<Functional_Queue_Member__c> userFqm = [
				SELECT Id, Functional_Queue__c, RecordTypeId
				FROM Functional_Queue_Member__c
				WHERE NCPS_User_Member__c = :UserInfo.getUserId().left(15) AND NCPS_Pending_Member__c = FALSE
			]; //NOSONAR
			Map<Id, Id> userFqMap = new Map<Id, Id>();

			for (Functional_Queue_Member__c fqm : userFqm) {
				if (fqm.RecordTypeId == ncpsFqmRtId) {
					userFqMap.put(fqm.Functional_Queue__c, fqm.Id);
				}
			}

			List<Id> fqIds = new List<Id>();
			for (Functional_Queue__c fq : newFqList) {
				if (ncpsFqRtIdMap.get(fq.RecordTypeId) != null) {
					fqIds.add(fq.Id);
				}
			}

			Map<Id, Functional_Queue__c> fqMap = new Map<Id, Functional_Queue__c>(
				[
					SELECT
						Id,
						RecordType.DeveloperName,
						NCPS_Parent_Functional_Queue__c,
						NCPS_Parent_Functional_Queue__r.NCPS_Parent_Functional_Queue__c,
						NCPS_Parent_Functional_Queue__r.NCPS_Parent_Functional_Queue__r.NCPS_Parent_Functional_Queue__c,
						NCPS_Category__c
					FROM Functional_Queue__c
					WHERE Id IN :fqIds
				]
			); //NOSONAR

			for (Functional_Queue__c fq : newFqList) {
				if (ncpsFqRtIdMap.get(fq.RecordTypeId) != null) {
					List<Id> allowedQueueIds = new List<Id>();

					Boolean membersChanged = fq.Number_of_Members__c != oldFqMap?.get(fq.Id)?.Number_of_Members__c;
					Boolean groupSet = fq.Public_Group_ID__c != null && oldFqMap?.get(fq.Id)?.Public_Group_ID__c == null;
					Boolean activeStatusChanged = fq.NCPS_Inactive__c != oldFqMap?.get(fq.Id)?.NCPS_Inactive__c;
					Boolean nameChanged = fq.Name != oldFqMap?.get(fq.Id)?.Name;
					Boolean descriptionChanged = fq.Description__c != oldFqMap?.get(fq.Id)?.Description__c;
					Boolean isAllowedUpdate;

					if (fqMap.get(fq.Id).RecordType.DeveloperName == 'NCPS_Alerts_Recalls_Facility_Level_2_Functional_Queue') {
						isAllowedUpdate = op == 'update' && (membersChanged || groupSet || activeStatusChanged || nameChanged || descriptionChanged);

						// if the number of queue members is changing, or the public group is being set from null,
						// then membership is being managed. also allow description edits.
						if (isAllowedUpdate) {
							// allow edit by parent member (facility level 1)
							allowedQueueIds.add(fqMap.get(fq.Id).NCPS_Parent_Functional_Queue__c);

							// allow edit by grandparent member (VISN)
							allowedQueueIds.add(fqMap.get(fq.Id).NCPS_Parent_Functional_Queue__r.NCPS_Parent_Functional_Queue__c);

							// allow edit by great-grandparent member (National)
							allowedQueueIds.add(fqMap.get(fq.Id).NCPS_Parent_Functional_Queue__r.NCPS_Parent_Functional_Queue__r.NCPS_Parent_Functional_Queue__c);
						}
						// if the number of queue members is not changing, the queue is being modified directly
						else if (op == 'insert') {
							// allow great-grandparent member (National)
							allowedQueueIds.add(fqMap.get(fq.Id).NCPS_Parent_Functional_Queue__r.NCPS_Parent_Functional_Queue__r.NCPS_Parent_Functional_Queue__c);

							// allow FRCs to create FDAS queue
							if (fqMap.get(fq.Id).NCPS_Category__c == 'FDAS') {
								allowedQueueIds.add(fqMap.get(fq.Id).NCPS_Parent_Functional_Queue__c);
							}
						}
					} else if (
						fqMap.get(fq.Id).RecordType.DeveloperName == 'NCPS_Alerts_Recalls_Facility_Level_1_2_Functional_Queue' ||
						fqMap.get(fq.Id).RecordType.DeveloperName == 'NCPS_Alerts_Recalls_Facility_Level_1_Functional_Queue'
					) {
						isAllowedUpdate = op == 'update' && (membersChanged || groupSet || activeStatusChanged);

						// if the number of queue members is changing, then membership is being managed
						if (isAllowedUpdate) {
							// allow edit by queue member (facility level 1)
							allowedQueueIds.add(fq.Id);

							// allow edit by parent member (VISN)
							allowedQueueIds.add(fqMap.get(fq.Id).NCPS_Parent_Functional_Queue__c);

							// allow edit by grandparentparent member (National)
							allowedQueueIds.add(fqMap.get(fq.Id).NCPS_Parent_Functional_Queue__r.NCPS_Parent_Functional_Queue__c);
						}
						// if the number of queue members is not changing, the queue is being modified directly
						else if (op == 'insert') {
							// allow grandparent member (National)
							allowedQueueIds.add(fqMap.get(fq.Id).NCPS_Parent_Functional_Queue__r.NCPS_Parent_Functional_Queue__c);
						}
					} else if (fqMap.get(fq.Id).RecordType.DeveloperName == 'NCPS_VISN_Functional_Queue') {
						isAllowedUpdate = op == 'update' && (membersChanged || groupSet || activeStatusChanged);

						// if the number of queue members is changing, then membership is being managed
						if (isAllowedUpdate) {
							// allow VISN users for workstreams other than RFU to manage their own VISN queue membership
							if (fq.NCPS_Category__c != 'NRC') {
								// allow edit by queue member (VISN)
								allowedQueueIds.add(fq.Id);
							}

							// allow edit by parent member (National)
							allowedQueueIds.add(fqMap.get(fq.Id).NCPS_Parent_Functional_Queue__c);
						}
						// if the number of queue members is not changing, the queue is being modified directly
						else if (op == 'insert') {
							// allow parent member (National)
							allowedQueueIds.add(fqMap.get(fq.Id).NCPS_Parent_Functional_Queue__c);
						}
					} else if (fqMap.get(fq.Id).RecordType.DeveloperName == 'NCPS_National_Functional_Queue') {
						isAllowedUpdate = op == 'update' && (membersChanged || groupSet || activeStatusChanged);

						if (isAllowedUpdate) {
							// allow adding by queue member (National)
							allowedQueueIds.add(fq.Id);
						}
					}

					Boolean userAllowedToCreateMember = false;
					for (Id queueId : allowedQueueIds) {
						if (userFqMap.get(queueId) != null) {
							userAllowedToCreateMember = true;
							break;
						}
					}

					if (!userAllowedToCreateMember) {
						fq.addError('You do not have the necessary permissions to ' + (op == 'insert' ? 'create' : op) + ' this Functional Queue.');
					} else if (op == 'update' && fq.Number_of_Members__c != oldFqMap.get(fq.Id).Number_of_Members__c) {
						fqsToClearPendingMembers.add(fq.Id);
					}
				}
			}
		} else if (op == 'update') {
			for (Functional_Queue__c fq : newFqList) {
				if (ncpsFqRtIdMap.get(fq.RecordTypeId) != null && fq.Number_of_Members__c != oldFqMap.get(fq.Id).Number_of_Members__c) {
					fqsToClearPendingMembers.add(fq.Id);
				}
			}
		}

		if (fqsToClearPendingMembers.size() > 0) {
			if (Schema.sObjectType.Functional_Queue_Member__c.isUpdateable()) {
				List<Functional_Queue_Member__c> fqMembers = [
					SELECT Id
					FROM Functional_Queue_Member__c
					WHERE User_Is_Active__c = TRUE AND Functional_Queue__c IN :fqsToClearPendingMembers AND NCPS_Pending_Member__c = TRUE
					WITH SECURITY_ENFORCED
				];
				if (fqMembers.size() > 0) {
					for (Functional_Queue_Member__c fqm : fqMembers) {
						fqm.NCPS_Pending_Member__c = false;
					}
					update fqMembers;
				}
			}
		}
	}
}