/**
 * @description Bogus test class to try to pass Github workflows
 *
 * @author      David Schach
 * @since       2022
 */
@isTest
public without sharing class DeleteThisTest {
	@isTest
	private static void assert() {
		System.assertEquals(1, 1, 'Math is hard');
	}

	@IsTest
	private static void name() {
		List<Contact> cons = [SELECT Id FROM Contact];
		cons = null;
		User u;
		System.runAs(u) {
			Assert.isTrue(true, 'this');
		}

	}
}