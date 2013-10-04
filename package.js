Package.describe({
  summary: "Entity-component-system (ECS) and collection proxying for real-time games."
});

Package.on_use(function (api, where) {
  api.use('coffeescript', 'server');
  api.add_files('server_entity.coffee', 'server');
  api.export('Asteroid', 'server');
});

// Package.on_test(function (api) {
//   api.use('asteroid');

//   api.add_files('asteroid_tests.js', ['client', 'server']);
// });
