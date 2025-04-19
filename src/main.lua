function love.load()
   --rasterRoad1 = love.graphics.newImage("nolines.png")
   --rasterRoad2 = love.graphics.newImage("nolines2.png")
   rasterRoad1 = love.graphics.newImage("test1.png")
   rasterRoad2 = love.graphics.newImage("test2.png")
   rasterRoadWidth = rasterRoad1:getWidth()
   rasterRoadHeight = rasterRoad1:getHeight()
   screenWidth = 512
   screenHeight = 512
   horizonHeight = 320
   fixPointYOffset = 10
      
   
   roadShader=love.graphics.newShader
   [[
      extern Image rasterRoad1;
      extern Image rasterRoad2;
      extern vec4 zMap[256];
      extern number zOffset;
      extern number x;
      extern number curveX;
      extern number rasterRoadWidth;
      extern number screenWidth;
      extern number screenHeight;
      extern number horizonHeight;
      extern number fixPointYOffset;
		
      vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
      {
         float screenY=screenHeight-screen_coords.y;
         int index=int(screenY);
         int a=int(index/256);
         int b=int(mod(index,256));
         float z = (zMap[b])[a];			
			
         float xCoord=screen_coords.x-x*screenWidth*(1-screenY/horizonHeight)-curveX*z*screenWidth;
         float xOffset=(rasterRoadWidth-screenWidth)/2;
         float xFactor=1/rasterRoadWidth;
         float texelX=(xCoord+xOffset)*xFactor;
         float texelY=1-screenY/(horizonHeight+fixPointYOffset);
         if (texelX>1) texelX=1;
         if (texelX<0) texelX=0;
         if (texelY>1) texelY=1;
         if (texelY<0) texelY=0;
         vec4 texcolor = Texel(rasterRoad1,vec2(texelX,texelY));
         if (mod(z+zOffset,1)<=0.5) 
         texcolor = Texel(rasterRoad2,vec2(texelX,texelY));
         if (screenY>horizonHeight)
         texcolor = vec4(0,0,1,1);
         return texcolor;
      }
   ]]
   
   zMap = calculateZMap(-horizonHeight,horizonHeight,screenHeight)
   zOffset=0
   vZ=0
   z=0
   x=0
   vX=0
   curveVX=0
   curveX=0
   obj={}
   for i=1,80 do
      obj[i]={}
      if i<=40 then
         obj[i].x=1
      else
         obj[i].x=-1
      end
      obj[i].y=0
      obj[i].z=zMap[100]*1.5*(i%40)
   end


   roadShader:send("rasterRoad1",rasterRoad1)
   roadShader:send("rasterRoad2",rasterRoad2)
   roadShader:send("rasterRoadWidth",rasterRoadWidth)
   roadShader:send("screenWidth",screenWidth)
   roadShader:send("screenHeight",screenHeight)
   zMapVec={}
   for i=1,256 do
      zMapVec[i]={0,0,0,0}
   end
   for i=1,256 do
      for a=1,4 do
         zMapVec[i][a]=0
      end
   end
	
   for i=1,screenHeight do
      a=math.floor((i-1)/256)+1
      b=math.floor((i-1)%256)+1
      zMapVec[b][a]=zMap[i]
   end
   roadShader:send("zMap",unpack(zMapVec))
   roadShader:send("zOffset",zOffset)
   roadShader:send("x",x)
   roadShader:send("curveX",curveX)
   roadShader:send("horizonHeight",horizonHeight)
   roadShader:send("fixPointYOffset",fixPointYOffset)	
--   rectZ=-640/((640-rectY)-700)
end

function unpack (t, i)
      i = i or 1
      if t[i] ~= nil then
        return t[i], unpack(t, i + 1)
      end
    end

function love.update(dt)
   zOffset=zOffset+dt*vZ
   z=z+dt*vZ
   x=x+vX*dt
   curveX=curveX+curveVX*dt

   for i=1,80 do
      if obj[i].z-z<=0 then
         obj[i].z=z+zMap[100]*1.5*40
      end
   end
   
   --rectX=x*(1-rectY/320)+curveX*rectZ
   --rectY=-320/rectZ+640/2
   if zOffset>=1 then
      zOffset=0
   end
   roadShader:send("zOffset",zOffset)
   roadShader:send("x",x)
   roadShader:send("curveX",curveX)
end

function love.keypressed(key)
   if key == "up" then
      vZ=vZ+0.4
   end
   if key == "down" then
      vZ=vZ-0.4
   end
   if key == "left" then
      vX=vX+0.1
   end
   if key == "right" then
      vX=vX-0.1
   end
   if key == "x" then
      curveVX=curveVX+0.02
   end
   if key == "z" then
      curveVX=curveVX-0.02
   end
end

function calculateZMap(camHeight,horizonHeight,screenHeight)
   local zMap={}
   for screenY=1,screenHeight do
		if screenY>horizonHeight then zMap[screenY]=0 else
			zMap[screenY]=camHeight/(screenY-horizonHeight)
		end
   end
   return zMap
end

function drawRoadSideObjects()
   table.sort(obj,function(obj1,obj2) return obj1.z<obj2.z end)
   for i=80,1,-1 do
      local rectX=obj[i].x
      local rectY=obj[i].y-horizonHeight/(obj[i].z-z)+horizonHeight
      local rectZ=obj[i].z-z
      local scaleFactor=1/rectZ+fixPointYOffset/horizonHeight   -- add 50/512 if fixpoint is not at top, also below first rectY/512 becomes eg rectY/562 depending on virtual y of real fixpoint
      love.graphics.setColor(0,0,0,255)
      love.graphics.rectangle("fill", screenWidth/2+rectX*screenWidth*(1-rectY/(horizonHeight+fixPointYOffset))+x*screenWidth*(1-rectY/horizonHeight)+curveX*rectZ*screenWidth-10*scaleFactor, screenHeight-rectY-80*scaleFactor, 20*scaleFactor, 80*scaleFactor)
      love.graphics.setColor(255,0,255,255)
      love.graphics.rectangle("fill", screenWidth/2+rectX*screenWidth*(1-rectY/(horizonHeight+fixPointYOffset))+x*screenWidth*(1-rectY/horizonHeight)+curveX*rectZ*screenWidth-10*scaleFactor, screenHeight-rectY-100*scaleFactor, 20*scaleFactor, 20*scaleFactor)
   end
end

function love.draw()
   love.graphics.setShader(roadShader)
   love.graphics.rectangle("fill", 0, 0, 512, 512)
   love.graphics.setShader()
   drawRoadSideObjects()
   
   --love.graphics.draw(hamster, x, y)
   -- draw things
   love.graphics.setShader()
   -- draw more things
end