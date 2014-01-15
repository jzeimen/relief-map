#! /usr/bin/env ruby

#UL  DD: 39.79170° -105.26367°
#LR  DD: 39.73311° -105.18059°


class STL
	def initialize
		@list = Array.new
	end
	def add_triangle t
		t.unshift([0,0,0])
		@list << t
	end
	def save_ascii file_name
		File.open(file_name,"w") do | file |
			file.puts "solid"
			@list.each do |t|
				file.puts "\tfacet normal #{t[0][0]} #{t[0][1]} #{t[0][2]}"
				file.puts "\t\touter loop"
				file.puts "\t\t\tvertex #{t[1][0]} #{t[1][1]} #{t[1][2]}"
				file.puts "\t\t\tvertex #{t[2][0]} #{t[2][1]} #{t[2][2]}"
				file.puts "\t\t\tvertex #{t[3][0]} #{t[3][1]} #{t[3][2]}"
				file.puts "\t\tendloop"
				file.puts "\tendfacet"
			end
			file.puts "endsolid"
		end
	end
	def save_binary file_name
		File.open(file_name,"wb") do |file|
			file.print ([0]*80).pack("C*")
			file.print [@list.length].pack("L")
			@list.each do |t|
				file.print t.flatten.pack("f*")
				file.print ([0]*2).pack("C*")
			end
		end
	end
end

# #Flatirons
# 39.9987°N, 105.3191°W
# 39.9475°N, 105.2678°W

# D_NORTH = 40.000
# D_WEST = -105.3191
# D_EAST = -105.2478
# D_SOUTH = 39.9475

# Golden
D_NORTH = 39.79170
D_WEST = -105.26367
D_EAST = -105.18059
D_SOUTH = 39.73311



#Pixel 
WIDTH = 10812
HEIGHT = 10812

#Vertical Exaggeration
VERT_MULT = 2

#LAT and LONG of upper left hand pixel
NORTH = 40.00055555556
WEST = -106.0005555556
EAST = -104.9994444445
SOUTH = 38.99944444444

ANGULAR_WIDTH = EAST - WEST
ANGULAR_PX_WIDTH = ANGULAR_WIDTH/WIDTH
ANGULAR_HEIGHT = NORTH - SOUTH
ANGULAR_PX_HEIGHT = ANGULAR_HEIGHT/HEIGHT

puts "ANGULAR_WIDTH=" + ANGULAR_WIDTH.to_s
puts "ANGULAR_PX_WIDTH=" + ANGULAR_PX_WIDTH.to_s
puts "ANGULAR_HEIGHT=" + ANGULAR_HEIGHT.to_s
puts "ANGULAR_PX_HEIGHT=" + ANGULAR_PX_HEIGHT.to_s



#Calculate Cropping
sy = ((NORTH-D_NORTH) / ANGULAR_PX_HEIGHT).round
dy = ((D_NORTH-D_SOUTH) / ANGULAR_PX_HEIGHT).round
sx = ((D_WEST-WEST) / ANGULAR_PX_WIDTH).round
dx = ((D_EAST-D_WEST) / ANGULAR_PX_WIDTH).round

puts "Output image will start at (" + sx.to_s + "," + sy.to_s + ")"
puts "Output image would be " + dx.to_s + "x" + dy.to_s

puts "Reading File"
f = File.binread("floatn40w106_13.flt")
puts "Unpacking File"
a = f.unpack("f*")
f=0;
puts "First elevation=" + a[0].to_s
# puts "Finding min"
# MIN = a.min 
# puts "Min = " + MIN.to_s

puts "creating 2d array"
two_d = a.each_slice(WIDTH).to_a
puts "First elevation=" + two_d[0][0].to_s
puts "first half elevation" + two_d[0][WIDTH/2].to_s
puts "UR" + two_d[0][-1].to_s
puts "LL" + two_d[-1][0].to_s
puts "LR" + two_d[-1][-1].to_s
puts "sx,sy = " + two_d[sx][sy].to_s
a=0;
puts "Cropping"
cropped = two_d[sy...(sy+dy)]#.transpose[sx...dx+sx].transpose
cropped.map!{|x| x[sx...(dx+sx)]}
puts "sx,sy after crop= " + cropped[0][0].to_s
#cropped = two_d[0...500]#.transpose[sx...dx+sx].transpose
#cropped.map!{|x| x[0...500]}
#cropped = two_d.values_at(* two_d.each_index.select {|i| 0==(i%10)})
#cropped = cropped[cropped.length/2...-1]
#cropped.map!{|x| x.values_at(* x.each_index.select{|i|0==(i%10)})}
#cropped.map!{|x| x[x.length/2...-1]}
#cropped = cropped.transpose
puts cropped[0].length
puts cropped.length
two_d=0

MIN = cropped.flatten.min 
puts MIN
cropped.map! do |x|
	x.map!{|y| (y-MIN)*0.1*VERT_MULT}
end

puts cropped.flatten.max  
puts "Creating STL Data Structure"
cropped.reverse!
stl = STL.new
0.upto(cropped.length-2) do |y|
	0.upto(cropped[y].length-2) do |x|
		t = [[x+1, y+1, cropped[y+1][x+1]],
			 [  x, y+1,   cropped[y+1][x]],
			 [  x,   y,    cropped[y][x]]];

		stl.add_triangle t

		t = [[   x,   y,      cropped[y][x]],
			 [ x+1,   y,    cropped[y][x+1]],
			 [ x+1, y+1, cropped[y+1][x+1]]];

		stl.add_triangle t
	end
end

0.upto(cropped[0].length-2) do |x|
		t = [[   x, 0.0,            0.0],
			 [ x+1, 0.0,            0.0],
			 [   x, 0.0, cropped[0][x]]];
		stl.add_triangle t
		t = [[ x+1, 0.0,             0.0],
			 [ x+1, 0.0, cropped[0][x+1]],
			 [   x, 0.0, cropped[0][x]]];
		stl.add_triangle t
end

0.upto(cropped[0].length-2) do |x|
		t = [[   x, dy-1, cropped[dy-1][x]],
			 [ x+1, dy-1,            0.0],
			 [   x, dy-1,            0.0]];
		stl.add_triangle t
		t = [[   x, dy-1,   cropped[dy-1][x]],
			 [ x+1, dy-1, cropped[dy-1][x+1]],
			 [ x+1, dy-1,                0.0]];
		stl.add_triangle t	
end

0.upto(cropped.length-2) do |y|
		t = [[ 0.0,   y,           0.0],
			 [ 0.0,   y, cropped[y][0]],
			 [ 0.0, y+1,           0.0]];
		stl.add_triangle t
		t = [[ 0.0,   y,   cropped[y][0]],
			 [ 0.0, y+1, cropped[y+1][0]],
			 [ 0.0, y+1,             0.0]];
		stl.add_triangle t	
end

0.upto(cropped.length-2) do |y|
		t = [[ dx-1, y+1,              0.0],
			 [ dx-1,   y, cropped[y][dx-1]],
			 [ dx-1,   y,              0.0]];
		stl.add_triangle t
		t = [[ dx-1, y+1,                0.0],
			 [ dx-1, y+1, cropped[y+1][dx-1]],
			 [ dx-1,   y,   cropped[y][dx-1]]];
		stl.add_triangle t		
end

t = [[  0.0, dy-1, 0.0],
	 [ dx-1,  0.0, 0.0],
	 [  0.0,  0.0, 0.0]];
stl.add_triangle t
t = [[  0.0, dy-1, 0.0],
	 [ dx-1, dy-1, 0.0],
	 [ dx-1,  0.0, 0.0]];
stl.add_triangle t		
puts "Writing file"
stl.save_binary "stuffbin.stl"

