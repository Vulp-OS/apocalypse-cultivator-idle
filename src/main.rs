use bevy::prelude::*;
mod hello_tutorial;
mod shape_tutorial;
mod bloom_tutorial;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
//        .add_plugins(shape_tutorial::ShapePlugin) // Draw 2D Shapes Tutorial Plugin
//        .add_plugins(hello_tutorial::HelloPlugin) // Hello Tutorial Plugin
        .add_plugins(bloom_tutorial::BloomPlugin)
        .run();
}
