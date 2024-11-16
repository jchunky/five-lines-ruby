require "ruby2d"

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

INPUT = {
  UP: 0, DOWN: 1, LEFT: 2, RIGHT: 3
}

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

@inputs = []

def remove(tile)
  (0...@map.length).each do |y|
    (0...@map[y].length).each do |x|
      if @map[y][x] == tile
        @map[y][x] = TILE[:AIR]
      end
    end
  end
end

def move_to_tile(newx, newy)
  @map[@playery][@playerx] = TILE[:AIR]
  @map[newy][newx] = TILE[:PLAYER]
  @playerx = newx
  @playery = newy
end

def move_horizontal(dx)
  if @map[@playery][@playerx + dx] == TILE[:FLUX] ||
     @map[@playery][@playerx + dx] == TILE[:AIR]
    move_to_tile(@playerx + dx, @playery)
  elsif (@map[@playery][@playerx + dx] == TILE[:STONE] ||
    @map[@playery][@playerx + dx] == TILE[:BOX]) &&
        @map[@playery][@playerx + dx + dx] == TILE[:AIR] &&
        @map[@playery + 1][@playerx + dx] != TILE[:AIR]
    @map[@playery][@playerx + dx + dx] = @map[@playery][@playerx + dx]
    move_to_tile(@playerx + dx, @playery)
  elsif @map[@playery][@playerx + dx] == TILE[:KEY1]
    remove(TILE[:LOCK1])
    move_to_tile(@playerx + dx, @playery)
  elsif @map[@playery][@playerx + dx] == TILE[:KEY2]
    remove(TILE[:LOCK2])
    move_to_tile(@playerx + dx, @playery)
  end
end

def move_vertical(dy)
  if @map[@playery + dy][@playerx] == TILE[:FLUX] ||
     @map[@playery + dy][@playerx] == TILE[:AIR]
    move_to_tile(@playerx, @playery + dy)
  elsif @map[@playery + dy][@playerx] == TILE[:KEY1]
    remove(TILE[:LOCK1])
    move_to_tile(@playerx, @playery + dy)
  elsif @map[@playery + dy][@playerx] == TILE[:KEY2]
    remove(TILE[:LOCK2])
    move_to_tile(@playerx, @playery + dy)
  end
end

def update_game
  handle_inputs

  update_map
end

def handle_inputs
  until @inputs.empty?
    current = @inputs.pop
    if current == INPUT[:LEFT]
      move_horizontal(-1)
    elsif current == INPUT[:RIGHT]
      move_horizontal(1)
    elsif current == INPUT[:UP]
      move_vertical(-1)
    elsif current == INPUT[:DOWN]
      move_vertical(1)
    end
  end
end

def update_map
  (0...@map.length).to_a.reverse_each do |y|
    (0...@map[y].length).each do |x|
      update_tile(x, y)
    end
  end
end

def update_tile(x, y)
  if (@map[y][x] == TILE[:STONE] || @map[y][x] == TILE[:FALLING_STONE]) &&
     @map[y + 1][x] == TILE[:AIR]
    @map[y + 1][x] = TILE[:FALLING_STONE]
    @map[y][x] = TILE[:AIR]
  elsif (@map[y][x] == TILE[:BOX] || @map[y][x] == TILE[:FALLING_BOX]) &&
        @map[y + 1][x] == TILE[:AIR]
    @map[y + 1][x] = TILE[:FALLING_BOX]
    @map[y][x] = TILE[:AIR]
  elsif @map[y][x] == TILE[:FALLING_STONE]
    @map[y][x] = TILE[:STONE]
  elsif @map[y][x] == TILE[:FALLING_BOX]
    @map[y][x] = TILE[:BOX]
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
      if @map[y][x] == TILE[:FLUX]
        g.fill_style = "#ccffcc"
      elsif @map[y][x] == TILE[:UNBREAKABLE]
        g.fill_style = "#999999"
      elsif @map[y][x] == TILE[:STONE] || @map[y][x] == TILE[:FALLING_STONE]
        g.fill_style = "#0000cc"
      elsif @map[y][x] == TILE[:BOX] || @map[y][x] == TILE[:FALLING_BOX]
        g.fill_style = "#8b4513"
      elsif @map[y][x] == TILE[:KEY1] || @map[y][x] == TILE[:LOCK1]
        g.fill_style = "#ffcc00"
      elsif @map[y][x] == TILE[:KEY2] || @map[y][x] == TILE[:LOCK2]
        g.fill_style = "#00ccff"
      end

      if @map[y][x] != TILE[:AIR] && @map[y][x] != TILE[:PLAYER]
        g.fill_rect(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
      end
    end
  end
end

def draw_player(g)
  g.fill_style = "#ff0000"
  g.fill_rect(@playerx * TILE_SIZE, @playery * TILE_SIZE, TILE_SIZE, TILE_SIZE)
end

def gameLoop
  update_game
  draw
end

# ruby2d call to run the gameLoop
update do
  gameLoop
end

LEFT_KEY = "left"
UP_KEY = "up"
RIGHT_KEY = "right"
DOWN_KEY = "down"

on :key_down do |e|
  case e.key
  when LEFT_KEY, "a"
    @inputs.push(INPUT[:LEFT])
  when UP_KEY, "w"
    @inputs.push(INPUT[:UP])
  when RIGHT_KEY, "d"
    @inputs.push(INPUT[:RIGHT])
  when DOWN_KEY, "s"
    @inputs.push(INPUT[:DOWN])
  when "escape"
    close
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
show
