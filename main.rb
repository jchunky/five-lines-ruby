require "ruby2d"
require "delegate"

module Config
  TILE_SIZE = 30
  FPS = 30
  SLEEP = 1000 / FPS

  TILE = {
    AIR: 0,
    FLUX: 1,
    UNBREAKABLE: 2,
    PLAYER: 3,
    STONE: 4,
    FALLING_STONE: 5,
    BOX: 6,
    FALLING_BOX: 7,
    KEY1: 8,
    LOCK1: 9,
    KEY2: 10,
    LOCK2: 11,
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

    def move_horizontal(dx)
    end
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

module Tiles
  include Config

  class Air < SimpleDelegator
    include Config
    def update(x, y)
    end

    def move_vertical(dy)
      move_to_tile(playerx, playery + dy)
    end

    def move_horizontal(dx)
      move_to_tile(playerx + dx, playery)
    end

    def draw(g, x, y)
    end

    def stony? = false
    def boxy? = false
    def edible? = true
    def pushable? = false
    def air? = true
    def flux? = false
    def unbreakable? = false
    def player? = false
    def stone? = false
    def falling_stone? = false
    def box? = false
    def falling_box? = false
    def key1? = false
    def lock1? = false
    def key2? = false
    def lock2? = false
  end

  class Flux < SimpleDelegator
    include Config
    def update(x, y)
    end

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

    def stony? = false
    def boxy? = false
    def edible? = true
    def pushable? = false
    def air? = false
    def flux? = true
    def unbreakable? = false
    def player? = false
    def stone? = false
    def falling_stone? = false
    def box? = false
    def falling_box? = false
    def key1? = false
    def lock1? = false
    def key2? = false
    def lock2? = false
  end

  class Unbreakable < SimpleDelegator
    include Config
    def update(x, y)
    end

    def move_vertical(dy)
    end

    def move_horizontal(dx)
    end

    def draw(g, x, y)
      g.fill_style = "#999999"
      g.fill_rect(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
    end

    def stony? = false
    def boxy? = false
    def edible? = false
    def pushable? = false
    def air? = false
    def flux? = false
    def unbreakable? = true
    def player? = false
    def stone? = false
    def falling_stone? = false
    def box? = false
    def falling_box? = false
    def key1? = false
    def lock1? = false
    def key2? = false
    def lock2? = false
  end

  class Player < SimpleDelegator
    include Config
    def update(x, y)
    end

    def move_vertical(dy)
    end

    def move_horizontal(dx)
    end

    def draw(g, x, y)
    end

    def stony? = false
    def boxy? = false
    def edible? = false
    def pushable? = false
    def air? = false
    def flux? = false
    def unbreakable? = false
    def player? = true
    def stone? = false
    def falling_stone? = false
    def box? = false
    def falling_box? = false
    def key1? = false
    def lock1? = false
    def key2? = false
    def lock2? = false
  end

  class Stone < SimpleDelegator
    include Config
    def initialize(delegate, falling_state)
      super(delegate)
      @falling_state = falling_state
    end

    def update(x, y)
      if map[y + 1][x].air?
        map[y + 1][x] = Stone.new(self, FallingStates::Falling.new(self))
        map[y][x] = Air.new(self)
      elsif @falling_state.falling?
        map[y][x] = Stone.new(self, FallingStates::Resting.new(self))
      end
    end

    def move_vertical(dy)
    end

    def move_horizontal(dx)
      @falling_state.move_horizontal(self, dx)
    end

    def draw(g, x, y)
      g.fill_style = "#0000cc"
      g.fill_rect(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
    end

    def stony? = true
    def boxy? = false
    def edible? = false
    def pushable? = true
    def air? = false
    def flux? = false
    def unbreakable? = false
    def player? = false
    def stone? = @falling_state.resting?
    def falling_stone? = @falling_state.falling?
    def box? = false
    def falling_box? = false
    def key1? = false
    def lock1? = false
    def key2? = false
    def lock2? = false
  end

  class Box < SimpleDelegator
    include Config
    def initialize(delegate, falling_state)
      super(delegate)
      @falling_state = falling_state
    end

    def update(x, y)
      if map[y + 1][x].air?
        map[y + 1][x] = Box.new(self, FallingStates::Falling.new(self))
        map[y][x] = Air.new(self)
      elsif @falling_state.falling?
        map[y][x] = Box.new(self, FallingStates::Resting.new(self))
      end
    end

    def move_vertical(dy)
    end

    def move_horizontal(dx)
      @falling_state.move_horizontal(self, dx)
    end

    def draw(g, x, y)
      g.fill_style = "#8b4513"
      g.fill_rect(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
    end

    def stony? = false
    def boxy? = true
    def edible? = false
    def pushable? = true
    def air? = false
    def flux? = false
    def unbreakable? = false
    def player? = false
    def stone? = false
    def falling_stone? = false
    def box? = @falling_state.resting?
    def falling_box? = @falling_state.falling?
    def key1? = false
    def lock1? = false
    def key2? = false
    def lock2? = false
  end

  class Key1 < SimpleDelegator
    include Config
    def update(x, y)
    end

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

    def stony? = false
    def boxy? = false
    def edible? = false
    def pushable? = false
    def air? = false
    def flux? = false
    def unbreakable? = false
    def player? = false
    def stone? = false
    def falling_stone? = false
    def box? = false
    def falling_box? = false
    def key1? = true
    def lock1? = false
    def key2? = false
    def lock2? = false
  end

  class Lock1 < SimpleDelegator
    include Config
    def update(x, y)
    end

    def move_vertical(dy)
    end

    def move_horizontal(dx)
    end

    def draw(g, x, y)
      g.fill_style = "#ffcc00"
      g.fill_rect(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
    end

    def stony? = false
    def boxy? = false
    def edible? = false
    def pushable? = false
    def air? = false
    def flux? = false
    def unbreakable? = false
    def player? = false
    def stone? = false
    def falling_stone? = false
    def box? = false
    def falling_box? = false
    def key1? = false
    def lock1? = true
    def key2? = false
    def lock2? = false
  end

  class Key2 < SimpleDelegator
    include Config
    def update(x, y)
    end

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

    def stony? = false
    def boxy? = false
    def edible? = false
    def pushable? = false
    def air? = false
    def flux? = false
    def unbreakable? = false
    def player? = false
    def stone? = false
    def falling_stone? = false
    def box? = false
    def falling_box? = false
    def key1? = false
    def lock1? = false
    def key2? = true
    def lock2? = false
  end

  class Lock2 < SimpleDelegator
    include Config
    def update(x, y)
    end

    def move_vertical(dy)
    end

    def move_horizontal(dx)
    end

    def draw(g, x, y)
      g.fill_style = "#00ccff"
      g.fill_rect(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
    end

    def stony? = false
    def boxy? = false
    def edible? = false
    def pushable? = false
    def air? = false
    def flux? = false
    def unbreakable? = false
    def player? = false
    def stone? = false
    def falling_stone? = false
    def box? = false
    def falling_box? = false
    def key1? = false
    def lock1? = false
    def key2? = false
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
    when TILE[:AIR] then Air.new(self)
    when TILE[:FLUX] then Flux.new(self)
    when TILE[:UNBREAKABLE] then Unbreakable.new(self)
    when TILE[:PLAYER] then Player.new(self)
    when TILE[:STONE] then Stone.new(self, FallingStates::Resting.new(self))
    when TILE[:FALLING_STONE] then Stone.new(self, FallingStates::Falling.new(self))
    when TILE[:BOX] then Box.new(self, FallingStates::Resting.new(self))
    when TILE[:FALLING_BOX] then Box.new(self, FallingStates::Falling.new(self))
    when TILE[:KEY1] then Key1.new(self)
    when TILE[:LOCK1] then Lock1.new(self)
    when TILE[:KEY2] then Key2.new(self)
    when TILE[:LOCK2] then Lock2.new(self)
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
