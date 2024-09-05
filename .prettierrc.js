module.exports = {
	...require('@x2od/prettier-config'),
	$schema: 'https://json.schemastore.org/prettierrc',
	overrides: [
		{
			files: '*.{cmp,page,component}',
			options: {
				attributeGroups: ['^id$', '^name$', '$DEFAULT', '^html-', '^class$', 'aria-']
			}
		},
		{
			files: 'doc*/**/*.html',
			options: {
				parser: 'html',
				attributeGroups: ['$CODE_GUIDE']
			}
		}
	]
};
