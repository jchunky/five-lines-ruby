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

  LEFT_KEY = "left"
  UP_KEY = "up"
  RIGHT_KEY = "right"
  DOWN_KEY = "down"
end

module Input
  include Config

  class Left < SimpleDelegator
    def handle_input
      dx = -1
      map[playery][playerx + dx].move_horizontal(dx)
    end
  end

  class Right < SimpleDelegator
    def handle_input
      dx = 1
      map[playery][playerx + dx].move_horizontal(dx)
    end
  end

  class Up < SimpleDelegator
    def handle_input
      dy = -1
      map[playery + dy][playerx].move_vertical(dy)
    end
  end

  class Down < SimpleDelegator
    def handle_input
      dy = 1
      map[playery + dy][playerx].move_vertical(dy)
    end
  end
end

module FallingStates
  class Falling < SimpleDelegator
    def falling? = true
    def resting? = false

    def move_horizontal(dx) = nil
  end

  class Resting < SimpleDelegator
    def falling? = false
    def resting? = true

    def move_horizontal(tile, dx)
      if map[playery][playerx + dx + dx].air? &&
         !map[playery + 1][playerx + dx].air?
        map[playery][playerx + dx + dx] = tile
        move_to_tile(playerx + dx, playery)
      end
    end
  end
end

class FallStrategy < SimpleDelegator
  def initialize(delegate, falling_state)
    super(delegate)
    @falling_state = falling_state
  end

  def update(tile, x, y)
    if map[y + 1][x].air?
      tile.drop
      map[y + 1][x] = tile
      map[y][x] = Tiles::Air.new(tile)
    elsif falling?
      tile.rest
    end
  end

  def falling? = @falling_state.falling?
end

class Tile < SimpleDelegator
  include Config

  def update(x, y) = nil
  def move_vertical(dy) = nil
  def move_horizontal(dx) = nil
  def draw(g, x, y) = nil
  def drop = nil
  def rest = nil

  def falling? = false
  def air? = false
  def lock1? = false
  def lock2? = false
end

module Tiles
  include Config

  class Air < Tile
    def move_vertical(dy)
      move_to_tile(playerx, playery + dy)
    end

    def move_horizontal(dx)
      move_to_tile(playerx + dx, playery)
    end

    def air? = true
  end

  class Flux < Tile
    def move_vertical(dy)
      move_to_tile(playerx, playery + dy)
    end

    def move_horizontal(dx)
      move_to_tile(playerx + dx, playery)
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
    attr_reader :falling_state

    def initialize(delegate, falling_state)
      super(delegate)
      @falling_state = falling_state
      @fall_strategy = FallStrategy.new(self, @falling_state)
    end

    def update(x, y)
      @fall_strategy.update(self, x, y)
    end

    def move_horizontal(dx)
      @falling_state.move_horizontal(self, dx)
    end

    def draw(g, x, y)
      g.fill_style = "#0000cc"
      g.fill_rect(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
    end

    def falling? = @falling_state.falling?
    def drop = @falling_state = FallingStates::Falling.new(self)
    def rest = @falling_state = FallingStates::Resting.new(self)
  end

  class Box < Tile
    attr_reader :falling_state

    def initialize(delegate, falling_state)
      super(delegate)
      @falling_state = falling_state
      @fall_strategy = FallStrategy.new(self, @falling_state)
    end

    def update(x, y)
      @fall_strategy.update(self, x, y)
    end

    def move_horizontal(dx)
      @falling_state.move_horizontal(self, dx)
    end

    def draw(g, x, y)
      g.fill_style = "#8b4513"
      g.fill_rect(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
    end

    def falling? = @falling_state.falling?
    def drop = @falling_state = FallingStates::Falling.new(self)
    def rest = @falling_state = FallingStates::Resting.new(self)
  end

  class Key1 < Tile
    def move_vertical(dy)
      remove_lock1
      move_to_tile(playerx, playery + dy)
    end

    def move_horizontal(dx)
      remove_lock1
      move_to_tile(playerx + dx, playery)
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
      move_to_tile(playerx, playery + dy)
    end

    def move_horizontal(dx)
      remove_lock2
      move_to_tile(playerx + dx, playery)
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

  attr_accessor :map, :playerx, :playery

  def run
    @playerx = 1
    @playery = 1

    @map = [
      [2, 2, 2, 2, 2, 2, 2, 2],
      [2, 3, 0, 1, 1, 2, 0, 2],
      [2, 4, 2, 6, 1, 2, 0, 2],
      [2, 8, 4, 1, 1, 2, 0, 2],
      [2, 4, 1, 1, 1, 9, 0, 2],
      [2, 2, 2, 2, 2, 2, 2, 2],
    ]
    transform_map

    @inputs = []

    # ruby2d call to run the game_loop
    Window.update do
      game_loop
    end

    Window.on :key_down do |e|
      case e.key
      when LEFT_KEY, "a"
        @inputs.push(Left.new(self))
      when UP_KEY, "w"
        @inputs.push(Up.new(self))
      when RIGHT_KEY, "d"
        @inputs.push(Right.new(self))
      when DOWN_KEY, "s"
        @inputs.push(Down.new(self))
      when "escape"
        close
      end
    end

    @document = Object.new

    def @document.get_element_by_id(id)
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
    @map.count.times do |y|
      @map.first.count.times do |x|
        @map[y][x] = transform_tile(@map[y][x])
      end
    end
  end

  def transform_tile(tile)
    case tile
    when TILE[:air] then Air.new(self)
    when TILE[:flux] then Flux.new(self)
    when TILE[:unbreakable] then Unbreakable.new(self)
    when TILE[:player] then Player.new(self)
    when TILE[:stone] then Stone.new(self, FallingStates::Resting.new(self))
    when TILE[:falling_stone] then Stone.new(self, FallingStates::Falling.new(self))
    when TILE[:box] then Box.new(self, FallingStates::Resting.new(self))
    when TILE[:falling_box] then Box.new(self, FallingStates::Falling.new(self))
    when TILE[:key1] then Key1.new(self)
    when TILE[:lock1] then Lock1.new(self)
    when TILE[:key2] then Key2.new(self)
    when TILE[:lock2] then Lock2.new(self)
    end
  end

  def remove_lock1
    (0...@map.length).each do |y|
      (0...@map[y].length).each do |x|
        if @map[y][x].lock1?
          @map[y][x] = Air.new(self)
        end
      end
    end
  end

  def remove_lock2
    (0...@map.length).each do |y|
      (0...@map[y].length).each do |x|
        if @map[y][x].lock2?
          @map[y][x] = Air.new(self)
        end
      end
    end
  end

  def move_to_tile(newx, newy)
    @map[@playery][@playerx] = Air.new(self)
    @map[newy][newx] = Player.new(self)
    @playerx = newx
    @playery = newy
  end

  def update_game
    handle_inputs

    update_map
  end

  def handle_inputs
    @inputs.pop.handle_input until @inputs.empty?
  end

  def update_map
    (0...@map.length).to_a.reverse_each do |y|
      (0...@map[y].length).each do |x|
        map[y][x].update(x, y)
      end
    end
  end

  def draw
    g = create_graphics
    draw_map(g)
    draw_player(g)
  end

  def create_graphics
    canvas = @document.get_element_by_id("GameCanvas")
    g = canvas.get_context("2d")
    g.clear_rect(0, 0, canvas.width, canvas.height)
    g
  end

  def draw_map(g)
    (0...@map.length).each do |y|
      (0...@map[y].length).each do |x|
        @map[y][x].draw(g, x, y)
      end
    end
  end

  def draw_player(g)
    g.fill_style = "#ff0000"
    g.fill_rect(@playerx * TILE_SIZE, @playery * TILE_SIZE, TILE_SIZE, TILE_SIZE)
  end

  def game_loop
    update_game
    draw
  end
end

Main.new.run
