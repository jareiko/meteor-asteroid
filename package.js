Package.describe({
  name: 'asteroid',
  summary: 'Entity-component-system (ECS) and collection proxying for real-time games.',
  version: '0.0.7',
  git: 'https://github.com/jareiko/meteor-asteroid.git'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0');
  api.export('Asteroid');
  api.addFiles('entity.js');
  api.addFiles('entitycollection.js');
  api.addFiles('entitysystem.js');
  api.addFiles('components.js');
});

Package.onTest(function(api) {
  api.use('tinytest');
  api.use('asteroid');
  api.addFiles('asteroid-tests.js');
});
