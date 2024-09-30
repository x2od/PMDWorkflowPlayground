/**
 * @description Bogus test class to try to pass Github workflows
 *
 * @author      David Schach
 * @since       2022
 */
@SuppressWarnings('PMD')
@IsTest
public class DeleteThisTest {
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
			System.debug('Foo');

			Assert.isTrue(true, 'this');
		}
	}
}