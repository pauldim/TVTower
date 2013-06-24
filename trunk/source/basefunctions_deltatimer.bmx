superstrict
Import "basefunctions_events.bmx"
?Threaded
Import Brl.threads
?
'timer mode
Import Brl.timer
Import Brl.event
Import Brl.retro

'class for smooth framerates

Type TDeltaTimer
	field newTime:int 				= 0
	field oldTime:int 				= 0.0
	field loopTime:float			= 0.1
	field nextDraw:float			= 0.0
	field accumulator:float			= 0.0
	field tweenValue:float			= 0.0		'between 0..1 (0 = no tween, 1 = full tween)

	field fps:int 					= 0
	field ups:int					= 0
	field currentUps:int			= 0
	field currentFps:int			= 0
	field timesDrawn:int 			= 0
	field timesUpdated:int 			= 0
	field secondGone:float 			= 0.0

	field totalTime:float 			= 0.0

	?Threaded
	Global UpdateThread:TThread
	Global drawMutex:TMutex 		= CreateMutex()
	Global useDeltaTimer:TDeltaTimer= null

	field mainLoopTime:float		= 0.1
	field mainLoopTimeAvg5:float	= 0.1
	field mainLoopTimeAvg10:float	= 0.1
	field mainNewTime:int			= 0
	field mainOldTime:int			= 0.0

	?

	Function Create:TDeltaTimer(physicsFps:int = 60, graphicsFps:int = -1)
		local obj:TDeltaTimer	= new TDeltaTimer
		obj.ups					= physicsFps
		obj.fps					= graphicsFps
		obj.newTime				= MilliSecs()
		obj.oldTime				= 0.0
		return obj
	End Function

	?Threaded
	Function RunUpdateThread:Object(Input:Object)
		repeat
			useDeltaTimer.newTime		= MilliSecs()
			if useDeltaTimer.oldTime = 0.0 then useDeltaTimer.oldTime = useDeltaTimer.newTime - 1
			useDeltaTimer.secondGone	:+ (useDeltaTimer.newTime - useDeltaTimer.oldTime)
			useDeltaTimer.loopTime		= (useDeltaTimer.newTime - useDeltaTimer.oldTime) / 1000.0
			useDeltaTimer.oldTime		= useDeltaTimer.newTime

			if useDeltaTimer.secondGone >= 1000.0 'in ms
				useDeltaTimer.secondGone 	= 0.0
				useDeltaTimer.currentFps	= useDeltaTimer.timesDrawn
				useDeltaTimer.currentUps	= useDeltaTimer.timesUpdated
				useDeltaTimer.timesDrawn 	= 0
				useDeltaTimer.timesUpdated	= 0
			endif

			'fill time available for this loop
			useDeltaTimer.loopTime = Min(0.25, useDeltaTimer.loopTime)	'min 4 updates per seconds 1/4
			useDeltaTimer.accumulator :+ useDeltaTimer.loopTime

			if useDeltaTimer.accumulator >= useDeltaTimer.getDeltaTime()
				'wait for the drawMutex to are unlocked (no drawing process at the moment)
				'force lock as physical updates are crucial
				LockMutex(drawMutex)
				While useDeltaTimer.accumulator >= useDeltaTimer.getDeltaTime()
					useDeltaTimer.totalTime		:+ useDeltaTimer.getDeltaTime()
					useDeltaTimer.accumulator	:- useDeltaTimer.getDeltaTime()
					useDeltaTimer.timesUpdated	:+ 1
					EventManager.triggerEvent( TEventSimple.Create("App.onUpdate",null) )
				Wend
				UnLockMutex(drawMutex)
			else
				delay( floor(Max(1, 1000.0 * (useDeltaTimer.getDeltaTime() - useDeltaTimer.accumulator) - 1)) )
			endif
		forever
	End Function


	Method Loop()
		mainNewTime		= MilliSecs()
		if mainOldTime = 0.0 then mainOldTime = mainNewTime - 1
		mainLoopTime	= (mainNewTime - mainOldTime) / 1000.0
		mainOldTime		= mainNewTime

		'init update thread
		if not self.UpdateThread OR not ThreadRunning(self.UpdateThread)
			useDeltaTimer = self
			print " - - - - - - - - - - - - - - - - -"
			print "Start Updatethread: create thread."
			print " - - - - - - - - - - - - - - - - -"
			self.UpdateThread = CreateThread(self.RunUpdateThread, Null)
		endif

		'time for drawing?
		'- subtract looptime
		'  -> time lost for doing other things
		self.nextDraw :- mainLoopTime

		If self.fps < 0 OR (self.fps > 0 and self.nextDraw <= 0.0)
			'if we get the mutex (not updating now) -> send draw event
			if TryLockMutex(drawMutex)
				self.nextDraw = 1.0/float(self.fps)

				'how many % of ONE update are left - 1.0 would mean: 1 update missing
				'this is NOT related to the fps! but some event listeners may want that information
				self.tweenValue = self.accumulator / self.getDeltaTime()


				'draw gets tweenvalue (0..1)
				self.timesDrawn :+1
				EventManager.triggerEvent( TEventSimple.Create("App.onDraw", string(self.tweenValue)) )
				UnlockMutex(drawMutex)
			endif
		else
rem
			'avg time of a loop
			if self.timesDrawn mod 10 = 0
				self.mainLoopTimeAvg10 = self.mainLoopTime
			elseif self.timesDrawn mod 5 = 0
				self.mainLoopTimeAvg5 = self.mainLoopTime
			endif
			local avg:int = (self.mainLoopTimeAvg5+self.mainLoopTimeAvg10+self.mainLoopTime)/3
			'delay by a minimum of 1ms - subtract looptime (as "time of next run")
			delay Max(1, 1000.0*(self.nextDraw- avg) )
endrem
			'delay by a minimum of 1ms - subtract looptime (as "time of next run")
			delay floor(Max(1, 1000.0*(self.nextDraw - self.mainLoopTime) -1))
		EndIf
		'in a non threaded version we delay...
'		delay(2)
	End Method
	?

	?not Threaded

	'maybe this method is better
	Field isRunning:Int = True
	Field Timer:TTimer=null
	Field nextUpdateTick:Int,nextDrawTick:Int
	Method TimerLoop()
		if not Timer then timer = CreateTimer(100)
		self.newTime		= MilliSecs()
		if self.oldTime = 0.0 then self.oldTime = self.newTime - 1
		self.secondGone		:+ (self.newTime - self.oldTime)
		self.loopTime		= (self.newTime - self.oldTime) / 1000.0
		self.oldTime		= self.newTime

		if self.secondGone >= 1000.0 'in ms
			self.secondGone 	= 0.0
			self.currentFps		= self.timesDrawn
			self.currentUps		= self.timesUpdated
			self.timesDrawn 	= 0
			self.timesUpdated	= 0
		endif

	'	If MilliSecs() > nextUpdateTick +1000
	'		nextUpdateTick= MilliSecs()-1
	'	EndIf
		If MilliSecs() > nextUpdateTick
			EventManager.triggerEvent( TEventSimple.Create("App.onUpdate",null) )
			nextUpdateTick:+ ceil(1000.0/self.ups)
			self.timesUpdated:+1
		ElseIf MilliSecs() > nextDrawTick
			EventManager.triggerEvent( TEventSimple.Create("App.onDraw", string(self.tweenValue) ) )
			nextDrawTick= MilliSecs()+ ceil(1000.0/self.fps)
			self.tweenValue = ceil(1000.0/self.ups) / nextUpdateTick
			self.timesDrawn:+1
		EndIf
		WaitTimer Timer
	End Method

	Method Loop()
		self.newTime		= MilliSecs()
		if self.oldTime = 0.0 then self.oldTime = self.newTime - 1
		self.secondGone		:+ (self.newTime - self.oldTime)
		self.loopTime		= (self.newTime - self.oldTime) / 1000.0
		self.oldTime		= self.newTime

		if self.secondGone >= 1000.0 'in ms
			self.secondGone 	= 0.0
			self.currentFps		= self.timesDrawn
			self.currentUps		= self.timesUpdated
			self.timesDrawn 	= 0
			self.timesUpdated	= 0
		endif

		'fill time available for this loop
		self.loopTime = Min(0.25, self.loopTime)	'min 4 updates per seconds 1/4
		self.accumulator :+ self.loopTime


		'update gets deltatime - fraction of a second (speed = pixels per second)
		While self.accumulator >= self.GetDeltaTime()
			self.totalTime		:+ self.GetDeltaTime()
			self.accumulator	:- self.GetDeltaTime()
			self.timesUpdated	:+ 1
			EventManager.triggerEvent( TEventSimple.Create("App.onUpdate",null) )
		Wend

		'time for drawing?
		'- subtract looptime
		'  -> time lost for doing other things
		self.nextDraw	:- self.looptime

		If self.fps < 0 OR (self.fps > 0 and self.nextDraw <= 0.0)
			self.nextDraw = 1.0/float(self.fps)

			'how many % of ONE update are left - 1.0 would mean: 1 update missing
			'this is NOT related to the fps! but some event listeners may want that information
			self.tweenValue = self.accumulator / self.getDeltaTime()
			'self.tweenValue:+ self.accumulator * self.ups

			'draw gets tweenvalue (0..1)
			self.timesDrawn :+1
			EventManager.triggerEvent( TEventSimple.Create("App.onDraw", string(self.tweenValue) ) )
		else
			'delay by a minimum of 2ms
			delay Max(1, self.nextDraw - self.looptime)
			'delay( self.nextDraw - self.looptime)
		EndIf
	End Method
	?
	'tween value = oldposition*tween + (1-tween)*newPosition
	'so its 1 if no movement, 0 for full movement to new position
	'each drawing function has to take care of it by itself
	Method getTween:float()
		return self.tweenValue
	End Method

	'time between physical updates as fraction to a second
	'used to be able to give "velocity" in pixels per second (dx = 100 means 100px per second)
	Method getDeltaTime:float()
		return 1.0/self.ups
	End Method
End Type



