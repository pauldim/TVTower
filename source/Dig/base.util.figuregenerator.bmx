SuperStrict
Import Brl.LinkedList
Import "base.gfx.imagehelper.bmx"
Import "base.util.registry.bmx"
Import "base.util.registry.spriteloader.bmx"

new TRegistryFigureGeneratorPartLoader.Init()


Type TFigureGenerator
	Global registeredParts:TList[14]

	Function RegisterPart(part:TFigureGeneratorPart)
		if part.partType < 1 or part.partType > registeredParts.length then return
		local index:int = part.partType -1
		
		if not registeredParts[index] then registeredParts[index] = CreateList()
		if not registeredParts[index].contains(part)
			registeredParts[index].Addlast(part)
		endif
	End Function


	Function GetRandomPart:TFigureGeneratorPart(partType:int, gender:int=0, age:int=0)
		if partType < 1 or partType > registeredParts.length then return Null
		if not registeredParts[partType-1] then return Null

		local index:int = partType -1

		'quick selection
		if gender = 0 and age = 0
			return TFigureGeneratorPart(registeredParts[index].ValueAtIndex(Rand(0, registeredParts[index].Count()-1 )))
		endif

		'need to filter
		local potentialParts:TFigureGeneratorPart[]
		for local p:TFigureGeneratorPart = EachIn registeredParts[index]
			if p.gender <> 0 and p.gender <> gender then continue
			if p.age <> 0 and p.age <> age then continue
			potentialParts :+ [p]
		next
		if potentialParts.length = 0 then return null
		return potentialParts[ Rand(0, potentialParts.length-1) ]
	End Function
	

	Function GenerateFigure:TFigureGeneratorFigure(skinTone:int, gender:int, age:int=0)
		local fig:TFigureGeneratorFigure = new TFigureGeneratorFigure
		if gender = 0 then gender = Rand(1,2)
		if skintone = 0 then skinTone = Rand(1,3)

		For local i:int = 1 to registeredParts.length
			local partType:int = TFigureGeneratorFigure.partOrder[i-1]
			if TFigureGeneratorFigure.useChance[i-1] <> 100
				if Rand(100) > TFigureGeneratorFigure.useChance[i-1] then continue
			endif
			local part:TFigureGeneratorPart = GetRandomPart(partType, gender, age)
			if part
				'got a gender specific part? use for rest
				if part.gender <> 0 then gender = part.gender
				if part.age <> 0 then age = part.age
			endif
			fig.SetPart(partType, part)
		Next
		'now gender and age are assured
		fig.gender = gender
		fig.age = age

		fig.SetSkinTone(skinTone) 
		fig.ColorizeElements()
		return fig
	End Function
End Type


Type TFigureGeneratorFigure
	Field gender:int = 0
	Field age:int = 0
	Field skinTone:int = 0
	Field parts:TFigureGeneratorPart[14]
	Field partsColor:TColor[14]
	
	Global partOrder:int[] = [  1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  14,  11,  12,  13]
	Global useChance:int[] = [100, 100, 100, 100, 100, 100, 100, 100, 100, 100,  25, 100, 100, 100]

	Method SetPart(partType:int, part:TFigureGeneratorPart = null)
		if partType < 1 or partType > parts.length then return
		
		parts[partType-1] = part
	End Method


	Method SetSkinTone(tone:int)
		skinTone = tone
		
		local mixColor:TColor
		Select tone
			case 1 'african
				local variation:int = Rand(1, 3)
				Select variation
					case 1	mixColor = new TColor.Create(106, 65, 46)
					case 2	mixColor = new TColor.Create(128, 87, 62)
					case 3	mixColor = new TColor.Create(165, 57,  0)
				End Select
			case 2 'asian
				local variation:int = Rand(1, 4)
				Select variation
					case 1	mixColor = new TColor.Create(255,220,177)
					case 2	mixColor = new TColor.Create(229,194,152)
					case 3	mixColor = new TColor.Create(204,132, 67)
					case 4	mixColor = new TColor.Create(223,185,151)
				EndSelect
'			case 3
			default 'european/caucasian
				local variation:int = Rand(1, 4)
				Select variation
					case 1	mixColor = new TColor.Create(255,218,204)
					case 2	mixColor = new TColor.Create(253,192,168)
					case 3	mixColor = new TColor.Create(233,145,110)
					case 4	mixColor = new TColor.Create(245,210,195)
				End Select
		EndSelect
		'add a bit variation
		mixColor.AdjustBrightness(Rand(10)/100.0 - 0.05)
		
		For local partType:int = eachin partOrder
			if not parts[partType -1] then continue
			if not parts[partType -1].skinVisible then continue
			partsColor[partType -1] = mixColor
		Next
	End Method


	Method ColorizeElements()
		'cloth
		if Rand(100) < 20
			if gender = 1
				partsColor[TFigureGeneratorPart.PART_CLOTH -1] =  new TColor.Create(Rand(8)*16,Rand(8)*32,Rand(8)*32)
			elseif gender = 2
				partsColor[TFigureGeneratorPart.PART_CLOTH -1] =  new TColor.Create(Rand(0,8)*32 -1,Rand(0,8)*32 -1,Rand(0,8)*16 -1)
			else
				partsColor[TFigureGeneratorPart.PART_CLOTH -1] =  new TColor.Create(Rand(8)*32,Rand(8)*32,Rand(8)*32)
			endif
			'minimum brightness
			if Rand(100) < 75
				partsColor[TFigureGeneratorPart.PART_CLOTH -1].AdjustBrightness( Rand(30)/100 ) '0% - 30%
			endif
		else
			Select Rand(16)
				case 1
					partsColor[TFigureGeneratorPart.PART_CLOTH -1] =  new TColor.Create(255, 180, 0)
				case 2
					partsColor[TFigureGeneratorPart.PART_CLOTH -1] =  new TColor.Create(100, 130, 0)
				case 3
					partsColor[TFigureGeneratorPart.PART_CLOTH -1] =  new TColor.Create(215, 210, 0)
				case 4
					partsColor[TFigureGeneratorPart.PART_CLOTH -1] =  new TColor.Create(120, 220, 0)
				case 5
					partsColor[TFigureGeneratorPart.PART_CLOTH -1] =  new TColor.Create(10, 220, 0)
				case 6
					partsColor[TFigureGeneratorPart.PART_CLOTH -1] =  new TColor.Create(0, 220, 120)
				case 7
					partsColor[TFigureGeneratorPart.PART_CLOTH -1] =  new TColor.Create(0, 180, 220)
				case 8
					partsColor[TFigureGeneratorPart.PART_CLOTH -1] =  new TColor.Create(0, 80, 220)
				case 9
					partsColor[TFigureGeneratorPart.PART_CLOTH -1] =  new TColor.Create(0, 80, 220)
				case 10
					partsColor[TFigureGeneratorPart.PART_CLOTH -1] =  new TColor.Create(220, 0, 40)
				case 11
					partsColor[TFigureGeneratorPart.PART_CLOTH -1] =  new TColor.Create(40, 220, 0)
				case 12
					partsColor[TFigureGeneratorPart.PART_CLOTH -1] =  new TColor.Create(40, 0, 220)
				case 13 'dark gray
					partsColor[TFigureGeneratorPart.PART_CLOTH -1] =  new TColor.Create(100, 100, 100)
				case 14 'light gray
					partsColor[TFigureGeneratorPart.PART_CLOTH -1] =  new TColor.Create(230, 230, 230)
				case 15
					partsColor[TFigureGeneratorPart.PART_CLOTH -1] =  new TColor.Create(150, 150, 150)
				default 'blackish
					partsColor[TFigureGeneratorPart.PART_CLOTH -1] =  new TColor.Create(35, 35, 35)
			End Select
			partsColor[TFigureGeneratorPart.PART_CLOTH -1].AdjustBrightness( Rand(30)/100 - 0.2 ) '-15% - 15%
		endif


		'hair
		local chanceBlonde:int = 20
		local chanceBlack:int = 38
		local chanceBrown:int = 28
		local chanceRed:int = 9
		local chanceCrazy:int = 5
		
		if skinTone = 1 'african
			chanceBlonde = 5
			chanceBlack = 60
			chanceBrown = 20
			chanceRed = 10
			chanceCrazy = 5
		elseif skinTone = 2 'asian
			chanceBlonde = 2
			chanceBlack = 75
			chanceBrown = 8
			chanceRed = 5
			if gender = 2
				chanceCrazy = 10
			else
				chanceBlack = 83
				chanceCrazy = 2
			endif
		endif
		local hairColor:TColor
		local hairTone:int = Rand(100)
		if hairTone < chanceBlonde
			haircolor = new TColor.Create(225,200,45)
		elseif hairTone < chanceBlonde + chanceBlack
			haircolor = new TColor.Create(30,25,20)
		elseif hairTone < chanceBlonde + chanceBlack + chanceBrown
			haircolor = new TColor.Create(80,30,10)
		else
			haircolor = new TColor.Create(255,100,0)
		endif
		haircolor.AdjustBrightness( Rand(30)/100 - 0.2 ) '-15% - 15%


		if age = 2 or Rand(100) < 5
			'desaturate a bit
'			haircolor.AdjustSaturationRGB( - 0.5 - 0.5 * Rand(100)/100.0)
		endif

		partsColor[TFigureGeneratorPart.PART_HAIR_BACK -1] = hairColor
		partsColor[TFigureGeneratorPart.PART_HAIR_FRONT -1] = hairColor
		partsColor[TFigureGeneratorPart.PART_BEARD -1] = hairColor
		partsColor[TFigureGeneratorPart.PART_EYEBROWS -1] = hairColor
	End Method


	Method GenerateImage:TImage()
		local img:TImage
		for local partType:int = eachin partOrder
			if not parts[partType -1] then continue
			if not parts[partType -1].sprite then continue

			if not img
				img = parts[partType -1].sprite.GetImageCopy()
				LockImage(img).ClearPixels(0)
			endif
			
			local col:TColor = partsColor[partType -1]
			if not col then col = TColor.clWhite
			DrawImageOnImage(parts[partType -1].sprite.GetImage(), img, 0, 0, col)
			'print "partIndex:"+(partType -1)+" col:"+col.ToString()+"  sprite:"+parts[partType -1].sprite.name
		Next
		'print "---------"
		return img
	End Method
		

	Method Draw(x:int, y:int)
		for local partType:int = eachin partOrder
			if not parts[partType -1] then continue
			parts[partType -1].Draw(x, y, partsColor[partType -1])
		Next
	End Method
End Type




Type TFigureGeneratorPart
	Field sprite:TSprite {nosave}
	Field spriteName:string
	Field partType:int
	Field gender:int = 0
	Field age:int = 0
	Field skinVisible:int = False

	Const PART_BG:int = 1
	Const PART_HAIR_BACK:int = 2
	Const PART_BODY:int = 3
	Const PART_NECK:int = 4
	Const PART_CLOTH:int = 5
	Const PART_FACE:int = 6
	Const PART_EYES:int = 7
	Const PART_EYES_IRIS:int = 8
	Const PART_NOSE:int = 9
	Const PART_EARS:int = 10
	Const PART_MOUTH:int = 11
	Const PART_HAIR_FRONT:int = 12
	Const PART_EYEBROWS:int = 13
	Const PART_BEARD:int = 14


	Method Init:TFigureGeneratorPart(sprite:TSprite, partType:int, gender:int = 0, age:int = 0, skinVisible:int=False)
		self.sprite = sprite
		if sprite
			self.spriteName = sprite.name
		else
			self.spriteName = ""
		endif
		self.partType = partType
		self.gender = gender
		self.age = age
		self.skinVisible = skinVisible
		
		return self
	End Method
	

	Method GetGUID:string()
		if sprite then return partType + "_" + sprite.name + "_" + gender + "_" +age
		return partType + "_" + "nosprite" + "_" + gender + "_" +age
	End Method
	

	Method Draw(x:int, y:int, color:TColor)
		if not sprite
			if spriteName
				sprite = GetSpriteFromRegistry(spriteName)
			else
				return
			endif
		endif
		
		if color
			local oldCol:TColor = new TColor.Get()
			oldCol.Copy().Mix(color).SetRGBA()
			sprite.Draw(x,y)
			oldCol.SetRGBA()
		else
			sprite.Draw(x,y)
		endif
	End Method
End Type





'===== NEWS GENRE LOADER =====
'loader caring about "<figuregeneratorpart>"
Type TRegistryFigureGeneratorPartLoader extends TRegistryBaseLoader
	Method Init:Int()
		name = "FigureGeneratorPart"
		resourceNames = "figuregeneratorpart|fgpart"
		if not registered then Register()
	End Method


	'creates - modifies default resource
	Method CreateDefaultResource:Int()
		'do nothign
	End Method


	Method GetConfigFromXML:TData(loader:TRegistryLoader, node:TxmlNode)
		local fieldNames:String[]
		local data:TData = new TData
		fieldNames :+ ["sprite", "age", "gender", "skin", "partType"]
		TXmlHelper.LoadValuesToData(node, data, fieldNames)

		return data
	End Method


	Method GetNameFromConfig:String(data:TData)
		return data.GetString("name","unknownfiguregenetatorpart")
	End Method


	Method LoadFromConfig:TFigureGeneratorPart(data:TData, resourceName:string)
		'create the figuregenerator part
		local spriteName:string = data.GetString("sprite", "")
		'load the sprite
		local sprite:TSprite = GetSpriteFromRegistry(spriteName)

		local partType:int = data.GetInt("partType", 0)
		local gender:int = data.GetInt("gender", 0)
		local age:int = data.GetInt("age", 0)
		local skin:int = data.GetInt("skin", 0)

		local part:TFigureGeneratorPart = new TFigureGeneratorPart.Init( sprite, partType, gender, age, skin)
		TFigureGenerator.RegisterPart( part )

		return part
	End Method
End Type