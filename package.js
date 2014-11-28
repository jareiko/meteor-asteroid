Package.describe({
  name: 'asteroid',
  summary: 'Entity-component-system (ECS) and collection proxying for real-time games.',
  version: '0.0.7',
  git: 'https://github.com/jareiko/meteor-asteroid.git',
  author: 'Jasmine Kent (http://twitter.com/jareiko)'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0');
  api.addFiles('entitycollection.js');
  api.addFiles('entitysystem.js');
  api.addFiles('components.js');
  api.export('Asteroid');
});

Package.onTest(function(api) {
  api.use(['tinytest', 'mdj:chai', 'mdj:sinon']);
  api.use('asteroid');
  api.addFiles('asteroid-tests.js');
});
