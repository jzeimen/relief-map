#! /usr/bin/env ruby

#Bounding_Coordinates from *meta.html file
FILENAME = "floatn40w106_13.flt"
OUT_FILENAME = "Golden.stl"
NORTH = 40.00055555556
WEST = -106.0005555556
EAST = -104.9994444445
SOUTH = 38.99944444444

#The coordinates for the bounding box around your area.
#This in particular is Golden, CO
D_NORTH = 39.79170
D_WEST = -105.26367
D_EAST = -105.18059
D_SOUTH = 39.73311

#Pixels How wide the .flt tile is. Row_count and column_count from the html file.
WIDTH = 10812
HEIGHT = 10812

#Vertical Exaggeration
VERT_MULT = 2

#How thin the thinnest part of the STL would be under the data.
BASE_THICKNESS = 10

#Basic error checking
if D_NORTH > NORTH || D_SOUTH < SOUTH || D_EAST > EAST || D_WEST < WEST then
	abort("The selected region is outside of the tile")
end

########### STL OUTPUT LOGIC 


class STL
	def initialize
		@list = Array.new
	end
	def add_triangle t
		t.unshift(normal(t))
		@list << t
	end

	def normal t
		a = [t[2][0]-t[1][0],t[2][1]-t[1][1],t[2][2]-t[1][2]]
		b = [t[0][0]-t[1][0],t[0][1]-t[1][1],t[0][2]-t[1][2]]
		#axb
		n=[ a[1]*b[2]-b[1]*a[2] , a[2]*b[0]-a[0]*b[2], a[0]*b[1]-b[0]*a[1]]
		length = Math.sqrt(n.inject(0){|m,x| m+x*x})
		return n.map{|x| x/length}
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
f = File.binread(FILENAME)
puts "Unpacking File"
a = f.unpack("f*")
f=0;


puts "creating 2d array"
two_d = a.each_slice(WIDTH).to_a
a=0;
puts "Cropping"
cropped = two_d[sy...(sy+dy)]
cropped.map!{|x| x[sx...(dx+sx)]}
puts "sx,sy after crop= " + cropped[0][0].to_s
two_d=0

MIN = cropped.flatten.min 
cropped.map! do |x|
	x.map!{|y| BASE_THICKNESS+(y-MIN)*0.1*VERT_MULT}
end

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
stl.save_binary OUT_FILENAME





