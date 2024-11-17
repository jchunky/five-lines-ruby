require "ruby2d"
require "delegate"

module Config
  TILE_SIZE = 30
  FPS = 30
  SLEEP = 1000 / FPS

  TILE = {
    air: 0,
    flux: 1,
    unbreakable: 2,
    player: 3,
    stone: 4,
    falling_stone: 5,
    box: 6,
    falling_box: 7,
    key1: 8,
    lock1: 9,
    key2: 10,
    lock2: 11,
  }

  KEY = {
    left: "left",
    up: "up",
    right: "right",
    down: "down",
    escape: "escape",
  }
end

module Input
  class Left
    def handle_input = $map[$playery][$playerx + -1].move_horizontal(-1)
  end

  class Right
    def handle_input = $map[$playery][$playerx + 1].move_horizontal(1)
  end

  class Up
    def handle_input = $map[$playery + -1][$playerx].move_vertical(-1)
  end

  class Down
    def handle_input = $map[$playery + 1][$playerx].move_vertical(1)
  end
end

class FallStrategy
  attr_accessor :falling_state

  def initialize(falling_state)
    @falling_state = falling_state
  end

  def falling? = @falling_state.falling?

  def update(tile, x, y)
    @falling_state = $map[y + 1][x].air? ? FallingStates::Falling.new : FallingStates::Resting.new
    drop(tile, x, y)
  end

  private

  def drop(tile, x, y)
    if @falling_state.falling?
      $map[y + 1][x] = tile
      $map[y][x] = Tiles::Air.new
    end
  end
end

module FallingStates
  class Falling
    def falling? = true
    def resting? = false

    def move_horizontal(tile, dx) = nil
  end

  class Resting
    def falling? = false
    def resting? = true

    def move_horizontal(tile, dx)
      if $map[$playery][$playerx + dx + dx].air? &&
         !$map[$playery + 1][$playerx + dx].air?
        $map[$playery][$playerx + dx + dx] = tile
        move_to_tile($playerx + dx, playery)
      end
    end
  end
end

class Tile
  include Config

  def update(x, y) = nil
  def move_vertical(dy) = nil
  def move_horizontal(dx) = nil
  def draw(g, x, y) = nil

  def air? = false
  def lock1? = false
  def lock2? = false
end

module Tiles
  class Air < Tile
    def move_vertical(dy)
      move_to_tile($playerx, $playery + dy)
    end

    def move_horizontal(dx)
      move_to_tile($playerx + dx, $playery)
    end

    def air? = true
  end

  class Flux < Tile
    def move_vertical(dy)
      move_to_tile($playerx, $playery + dy)
    end

    def move_horizontal(dx)
      move_to_tile($playerx + dx, $playery)
    end

    def draw(g, x, y)
      g.fill_style = "#ccffcc"
      g.fill_rect(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
    end
  end

  class Unbreakable < Tile
    def draw(g, x, y)
      g.fill_style = "#999999"
      g.fill_rect(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
    end
  end

  class Player < Tile
  end

  class Stone < Tile
    def initialize(falling_state)
      @fall_strategy = FallStrategy.new(falling_state)
    end

    def update(x, y)
      @fall_strategy.update(self, x, y)
    end

    def move_horizontal(dx)
      @fall_strategy.falling_state.move_horizontal(self, dx)
    end

    def draw(g, x, y)
      g.fill_style = "#0000cc"
      g.fill_rect(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
    end
  end

  class Box < Tile
    def initialize(falling_state)
      @fall_strategy = FallStrategy.new(falling_state)
    end

    def update(x, y)
      @fall_strategy.update(self, x, y)
    end

    def move_horizontal(dx)
      @fall_strategy.falling_state.move_horizontal(self, dx)
    end

    def draw(g, x, y)
      g.fill_style = "#8b4513"
      g.fill_rect(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
    end
  end

  class Key1 < Tile
    def move_vertical(dy)
      remove_lock1
      move_to_tile($playerx, $playery + dy)
    end

    def move_horizontal(dx)
      remove_lock1
      move_to_tile($playerx + dx, $playery)
    end

    def draw(g, x, y)
      g.fill_style = "#ffcc00"
      g.fill_rect(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
    end
  end

  class Lock1 < Tile
    def draw(g, x, y)
      g.fill_style = "#ffcc00"
      g.fill_rect(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
    end

    def lock1? = true
  end

  class Key2 < Tile
    def move_vertical(dy)
      remove_lock2
      move_to_tile($playerx, $playery + dy)
    end

    def move_horizontal(dx)
      remove_lock2
      move_to_tile($playerx + dx, $playery)
    end

    def draw(g, x, y)
      g.fill_style = "#00ccff"
      g.fill_rect(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
    end
  end

  class Lock2 < Tile
    def draw(g, x, y)
      g.fill_style = "#00ccff"
      g.fill_rect(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
    end

    def lock2? = true
  end
end

# Hacks to make the ruby2d API look/act similar to the JS canvas/context/graphics API
class GraphicsObject
  attr_accessor :fill_style

  def initialize
    @fill_style = ""
  end

  def clear_rect(x, y, width, height)
    Window.clear
    Rectangle.new(x: x, y: y, width: width, height: height, color: "white")
  end

  def fill_rect(x, y, width, height)
    Rectangle.new(x: x, y: y, width: width, height: height, color: @fill_style)
  end
end

class Main
  include Config
  include Input
  include Tiles

  def run
    $playerx = 1
    $playery = 1

    $map = [
      [2, 2, 2, 2, 2, 2, 2, 2],
      [2, 3, 0, 1, 1, 2, 0, 2],
      [2, 4, 2, 6, 1, 2, 0, 2],
      [2, 8, 4, 1, 1, 2, 0, 2],
      [2, 4, 1, 1, 1, 9, 0, 2],
      [2, 2, 2, 2, 2, 2, 2, 2],
    ]
    transform_map

    $inputs = []

    # ruby2d call to run the game_loop
    Window.update do
      game_loop
    end

    Window.on :key_down do |e|
      case e.key
      when KEY[:left], "a"
        $inputs.push(Left.new)
      when KEY[:up], "w"
        $inputs.push(Up.new)
      when KEY[:right], "d"
        $inputs.push(Right.new)
      when KEY[:down], "s"
        $inputs.push(Down.new)
      when KEY[:escape]
        Window.close
      end
    end

    $document = Object.new

    def $document.get_element_by_id(id)
      canvas = Object.new

      def canvas.get_context(context)
        GraphicsObject.new
      end

      def canvas.width
        Window.width
      end

      def canvas.height
        Window.height
      end

      canvas
    end

    # ruby2d call to make it all work
    Window.show
  end

  def transform_map
    $map.count.times do |y|
      $map.first.count.times do |x|
        $map[y][x] = transform_tile($map[y][x])
      end
    end
  end

  def transform_tile(tile)
    case tile
    when TILE[:air] then Air.new
    when TILE[:flux] then Flux.new
    when TILE[:unbreakable] then Unbreakable.new
    when TILE[:player] then Player.new
    when TILE[:stone] then Stone.new(FallingStates::Resting.new)
    when TILE[:falling_stone] then Stone.new(FallingStates::Falling.new)
    when TILE[:box] then Box.new(FallingStates::Resting.new)
    when TILE[:falling_box] then Box.new(FallingStates::Falling.new)
    when TILE[:key1] then Key1.new
    when TILE[:lock1] then Lock1.new
    when TILE[:key2] then Key2.new
    when TILE[:lock2] then Lock2.new
    end
  end

  def update_game
    handle_inputs

    update_map
  end

  def handle_inputs
    $inputs.pop.handle_input until $inputs.empty?
  end

  def update_map
    (0...$map.length).to_a.reverse_each do |y|
      (0...$map[y].length).each do |x|
        $map[y][x].update(x, y)
      end
    end
  end

  def draw
    g = create_graphics
    draw_map(g)
    draw_player(g)
  end

  def create_graphics
    canvas = $document.get_element_by_id("GameCanvas")
    g = canvas.get_context("2d")
    g.clear_rect(0, 0, canvas.width, canvas.height)
    g
  end

  def draw_map(g)
    (0...$map.length).each do |y|
      (0...$map[y].length).each do |x|
        $map[y][x].draw(g, x, y)
      end
    end
  end

  def draw_player(g)
    g.fill_style = "#ff0000"
    g.fill_rect($playerx * TILE_SIZE, $playery * TILE_SIZE, TILE_SIZE, TILE_SIZE)
  end

  def game_loop
    update_game
    draw
  end
end

def remove_lock1
  (0...$map.length).each do |y|
    (0...$map[y].length).each do |x|
      if $map[y][x].lock1?
        $map[y][x] = Tiles::Air.new
      end
    end
  end
end

def remove_lock2
  (0...$map.length).each do |y|
    (0...$map[y].length).each do |x|
      if $map[y][x].lock2?
        $map[y][x] = Tiles::Air.new
      end
    end
  end
end

def move_to_tile(newx, newy)
  $map[$playery][$playerx] = Tiles::Air.new
  $map[newy][newx] = Tiles::Player.new
  $playerx = newx
  $playery = newy
end

Main.new.run
