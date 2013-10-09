Package.describe({
  summary: "Entity-component-system (ECS) and collection proxying for real-time games."
});

Package.on_use(function (api, where) {
  api.use('coffeescript');
  api.add_files('entity.coffee');
  api.add_files('components.coffee');
  api.export('Asteroid');
});

// Package.on_test(function (api) {
//   api.use('asteroid');

//   api.add_files('asteroid_tests.js', ['client', 'server']);
// });
