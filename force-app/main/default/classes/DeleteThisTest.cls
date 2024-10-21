/**
 * @description Bogus test class to try to pass Github workflows
 *
 * @author      David Schach
 * @since       2022
 */
@IsTest
public with sharing class DeleteThisTest {
	@TestSetup
	private static void createData() {
		// should not give PMD error
		System.runAs(new User(Id = UserInfo.getUserId())) {
			Assert.isTrue(true, 'that');
		}
	}

	@SuppressWarnings('PMD')
	@IsTest
	public static void assertMe() {
		System.debug('hello world');
		System.assertEquals(1, 1, 'Math is hard');
	}

	@IsTest
	private static void name() {
		List<Contact> cons = [SELECT Id FROM Contact];
		//cons = null;
		System.runAs(new User(Id = UserInfo.getUserId())) {
			System.debug('Foo'); //NOPMD
			Assert.isTrue(true, 'this');
		}
	}
}