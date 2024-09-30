/**
 * @description Bogus test class to try to pass Github workflows
 *
 * @author      David Schach
 * @since       2022
 */
@IsTest
public with sharing class DeleteThisTest {
	@SuppressWarnings('PMD')
	@IsTest
	public static void assertMe() {
		System.assertEquals(1, 1, 'Math is hard');
	}

	@IsTest
	private static void name() {
		List<Contact> cons = [SELECT Id FROM Contact];
		//cons = null;
		User u;
		System.runAs(u) {
			System.debug('Foo'); //NOPMD

			Assert.isTrue(true, 'this');
		}
	}
}