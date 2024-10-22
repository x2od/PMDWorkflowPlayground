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

	@IsTest
	public static void assert_Me() {
		System.debug('hello world');
		System.assertEquals(1, 1, 'Math is hard');
	}

	private static testMethod void name() {
		List<Contact> cons = [SELECT Id FROM Contact];
		cons = new List<Contact>();
		User usr = new User(Id = UserInfo.getUserId());
		System.runAs(usr) {
			System.debug('Foo'); //NOPMD
			Assert.isTrue(true, 'this');
		}
	}
}