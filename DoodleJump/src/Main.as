package 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;

	/**
	 * ...
	 * @author vik
	 */
	[SWF(width = "320", height = "480", frameRate = "60", backgroundColor = "#FFFFFF")]
	[Frame(factoryClass = "Preloader")]
	
	public class Main extends Sprite 
	{
		[Embed(source = "../bin/assets/font/CMDestroy.ttf", fontName = "destroy",  embedAsCFF = "false")] static private const Destroy :Class; //font
		private var loaders :Vector.<Loader>; //liste des loaders
		private var bitmaps :Vector.<BitmapData>; //liste des bitmaps
		
		private var character :Sprite; //personnage
		private var playedBoards :Vector.<MovieClip>; //plateaux à animer
		
		private var boardsContainer :Sprite; //container des plateaux
		private var gameContainer :Sprite; //conteneur du jeu
		private var infoContainer :Sprite; //container des infos
		private var menuContainer :Sprite; //container du menu et des autres pages
		private var bkgContainer :Sprite; //container du background
		private var grid :Vector.<MovieClip>; //grille des plateaux
		
		private var moveLeft :Boolean; //se deplacer vers la gauche
		private var moveRight :Boolean; //se deplacer vers la droite
		private var pulse :Number; //impulsion
		
		private var spacing :Number; //ecartement entre les plateaux
		private var gravity :Number; //vitesse de la chute
		private var moveH :Number; //incrementation du mouvement horizontal
		private var normalPulse :Number; //impulsion de base
		private var levels :Array; //liste des valeurs des levels
		private var level :int; //level en cours
		
		private var stoned :int; //si le perso a mangé un champi -1;
		private var stoneTime :int; //temps ou le perso est stone
		
		private var bonus :Number; //total des bonus
		private var score :int; //score
		private var hight :Number; //altitude des plateaux
		private var hightscore :int; //hightscore
		
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		//init global
		private function init(e:Event = null):void {
			//supprimer le preloader
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			loadXml("assets/config.xml");
		}
		
		/////////////////////////////////// INIT /////////////////////////////////////////
		//loader le xml
		private function loadXml(xml :String) :void {
			var urlLoader :URLLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, initXML);
			urlLoader.load(new URLRequest(xml));
		}
		
		//initialiser le xml
		private function initXML(evt :Event) :void {
			//creer le xml
			var xml :XML = XML(evt.target.data);
			
			//charger les images
			loadBitmaps(xml);
			
			//initialiser les levels
			initLevels(xml);
		}
		
		//charger les images
		private function loadBitmaps(xml :XML) :void {
			//initialiser la liste des loaders
			loaders = new Vector.<Loader>();
			var loader :Loader;
			
			//charger les images du jeu
			for each(var image :XML in xml[0].gameImages.elements()) {
				loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, initBitmaps);
				loader.load(new URLRequest(image));
				loaders.push(loader);
			}
			
			//charger les images de l'interface
			for each(image in xml[0].interfaceImages.elements()) {
				loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, initBitmaps);
				loader.load(new URLRequest(image));
				loaders.push(loader);
			}
			
			//creer le tableau des bitmaps
			bitmaps = new Vector.<BitmapData>(loaders.length);
		}
		
		//initilaiser les images
		private function initBitmaps(evt :Event) :void {
			//definir le loader
			var loader :Loader = (evt.target as LoaderInfo).loader;
			
			//creer le bitmapData
			var bmd :BitmapData = new BitmapData(loader.width, loader.height, true, 0xFFFFFF);
			bmd.draw(loader);
			
			//definir l'index du loader
			for (var i :int = 0; i < loaders.length; i++) {
				if (loader == loaders[i]) {
					trace("img" + i + " loaded");
					bitmaps[i] = bmd;
					break;
				}
			}
			
			//arreter si toutes les images ne sont pas chargées sinon continuer
			for (i = 0; i < bitmaps.length; i++) {
				if (bitmaps[i] == null) return;
			}
			
			//initialiser l'interface et le jeu
			initInterface();
		}
		
		//initialiser l'interface
		private function initInterface() :void {
			//formatage du texte
			var tf :TextFormat = new TextFormat();
			tf.font = "destroy";
			tf.size = 24;
			tf.color = 0x111111;
			
			//creer le container du jeu
			gameContainer = new Sprite();
			addChild(gameContainer);
			
			//creer le container d'info
			infoContainer = new Sprite();
			addChild(infoContainer);
			
			//ajouter le score
			var scoreTf :TextField = new TextField();
			scoreTf.width = stage.stageWidth;
			scoreTf.x = 100;
			scoreTf.name = "score";
			infoContainer.addChild(scoreTf);
			
			scoreTf.embedFonts = true;
			scoreTf.autoSize = "center";
			scoreTf.wordWrap = true;
			scoreTf.defaultTextFormat = tf;
			
			
			//creer le container des autres pages
			menuContainer = new Sprite();
			addChild(menuContainer);
			
			//creer le menu
			var menu :Sprite = new Sprite();
			menuContainer.addChild(menu);
			menu.addChild(loaders[11]);
			
			//ajouter les boutons
			//menu principal
			var firstMenu :Sprite = new Sprite();
			menu.addChild(firstMenu);
			//firstMenu.visible = false;
			
			//btn play
			firstMenu.addChild(loaders[14]);
			var playBtn :DisplayObject = firstMenu.getChildAt(0);
			playBtn.x = 50;
			playBtn.y = 250;
			playBtn.addEventListener(MouseEvent.CLICK, showSecondMenu);
			
			//btn rules
			firstMenu.addChild(loaders[15]);
			var rulesBtn :DisplayObject = firstMenu.getChildAt(1);
			rulesBtn.x = 50;
			rulesBtn.y = 350;
			rulesBtn.addEventListener(MouseEvent.CLICK, showRules);
			
			//menu secondaire
			var secondMenu :Sprite = new Sprite();
			menu.addChild(secondMenu);
			secondMenu.visible = false;
			
			//btn niveaux
			for (var i :int = 0; i < 4; i++) {
				var btn :MovieClip = new MovieClip();
				secondMenu.addChild(btn);
				btn.addChild(loaders[16 + i]);
				if (i == 0 || i == 2) {
					btn.x = 20;
				} else {
					btn.x = 180;
				}
				if (i < 2) {
					btn.y = 250;
				} else {
					btn.y = 350;
				}
				
				btn.lvl = i;
				btn.addEventListener(MouseEvent.CLICK, showGame);
			}
			
			//creer la page rules
			var rules :Sprite = new Sprite();
			menuContainer.addChild(rules);
			rules.visible = false;
			rules.addChild(loaders[12]);
			rules.addEventListener(MouseEvent.CLICK, showFirstMenu);
			
			//creer la page loose
			var loose :Sprite = new Sprite();
			menuContainer.addChild(loose);
			loose.visible = false;
			loose.addChild(loaders[13]);
			
			//ajouter le texte au loose
			var txt :TextField = new TextField();
			txt.width = stage.stageWidth;
			loose.addChild(txt);
			
			txt.x = 50;
			txt.y = 100;
			
			txt.embedFonts = true;
			txt.autoSize = "left";
			txt.wordWrap = true;
			txt.defaultTextFormat = tf;
			
			loose.addEventListener(MouseEvent.CLICK, showFirstMenu);
		}
		
		//initialiser la phase de jeu
		private function initGame(lvl :int = 0) :void {
			//initialiser les valeurs
			score = 0;
			hight = 0;
			bonus = 0;
			setLevel(lvl);
			pulse = normalPulse * 2;
			stoneTime = 0;
			stoned = 1;
			
			//afficher les elements
			menuContainer.visible = false;
			gameContainer.visible = true;
			infoContainer.visible = true;
			
			//afficher le score au depart
			var scoreTf :TextField = infoContainer.getChildByName("score") as TextField;
			scoreTf.text = score.toString();
			
			//initialiser les elements
			initBkg();
			initGrid();
			initCharacter();
			initEvents();
		}
		
		//creer le personnage
		private function initCharacter() :void {
			//creer le personnage
			if (character != null) gameContainer.removeChild(character);
			character = new Sprite();
			
			//ajouter les images
			var chUp :Loader = loaders[0];
			character.addChild(chUp);
			
			var chDown :Loader = loaders[1];
			character.addChild(chDown);
			
			var chStoned :Loader = loaders[2];
			character.addChild(chStoned);
			
			//ajouter / placer le personnage dans le container du jeu
			gameContainer.addChild(character);
			character.y = 450;
			character.x = 145;
		}
		
		//initialiser la grille
		private function initGrid() :void {
			//initialiser la liste des plateaux
			grid = new Vector.<MovieClip>();
			playedBoards = new Vector.<MovieClip>();
			
			//creer le container des plateaux
			if (boardsContainer != null) gameContainer.removeChild(boardsContainer);
			boardsContainer = new Sprite();
			gameContainer.addChild(boardsContainer);
			
			//ajouter des plateaux
			createLines(12);
		}
		
		//creer le background
		private function initBkg() :void {
			//creer le container des backgrounds
			if (bkgContainer != null) gameContainer.removeChild(bkgContainer);
			bkgContainer = new Sprite();
			gameContainer.addChild(bkgContainer);
			
			//ajouter l'image
			var bitmap :Bitmap = new Bitmap(bitmaps[3]);
			bkgContainer.addChild(bitmap);
			
			//placer l'image
			bitmap.y = -bitmap.height + stage.stageHeight;
		}
		
		//creer les evenements
		private function initEvents() :void {
			//evenements clavier
			stage.addEventListener(KeyboardEvent.KEY_DOWN, pressKey);
			stage.addEventListener(KeyboardEvent.KEY_UP, releaseKey);
			
			//enterframe
			addEventListener(Event.ENTER_FRAME, update);
		}
		
		//definir les valeurs des levels
		private function initLevels(xml :XML) :void {
			levels = new Array();
			
			//ajouter les valeurs au level
			for each(var lvl :XML in xml[0].levels.level) {
				var lvlObject :Object = { };
				lvlObject.spacing = Number(lvl.spacing); //spacing
				//boardsPct
				var boardsPct :Array = new Array();
				for each(var b :XML in lvl.boardsPct.board) {
					boardsPct.push(Number(b));
				}
				lvlObject.boardsPct = boardsPct;
				//bonusPct
				var bonusPct :Array = new Array();
				for each(var bs :XML in lvl.bonusPct.bonus) {
					bonusPct.push(Number(bs));
				}
				lvlObject.bonusPct = bonusPct;
				lvlObject.gravity = Number(lvl.gravity); //gravity
				lvlObject.pulse = Number(lvl.pulse);//pulse
				lvlObject.moveH = Number(lvl.moveH);//moveH
				lvlObject.score = Number(lvl.score);//score
				
				//ajouter le level à la liste
				levels.push(lvlObject);
			}
			
			
			//level 00
			/*var level0 :Object = { };
			level0.spacing = 55;
			level0.boardsPct = [82, 5, 3, 2, 8];
			level0.bonusPct = [5, 1];
			level0.gravity = 0.4;
			level0.pulse = 11;
			level0.moveH = 4.2;
			level0.score = 5000;
			
			//level 01
			var level1 :Object = { };
			level1.spacing = 80;
			level1.boardsPct = [72, 10, 3, 8, 8];
			level1.bonusPct = [3, 2];
			level1.gravity = 0.7;
			level1.pulse = 16;
			level1.moveH = 5;
			level1.score = 10000;
			
			//level 02
			var level2 :Object = { };
			level2.spacing = 80;
			level2.boardsPct = [60, 8, 7, 10, 15];
			level2.bonusPct = [2, 3];
			level2.gravity = 1.2;
			level2.pulse = 21;
			level2.moveH = 6.3;
			level2.score = 20000;
			
			//level 03
			var level3 :Object = { };
			level3.spacing = 95;
			level3.boardsPct = [50, 5, 5, 15, 25];
			level3.bonusPct = [1, 4];
			level3.gravity = 2;
			level3.pulse = 30;
			level3.moveH = 7.3;
			level3.score = 30000;
			
			//level 04
			var level4 :Object = { };
			level4.spacing = 110;
			level4.boardsPct = [30, 2, 1, 32, 35];
			level4.bonusPct = [0, 7];
			level4.gravity = 3;
			level4.pulse = 40;
			level4.moveH = 8.5;
			level4.score = 40000;
			
			levels = [level0, level1, level2, level3, level4];*/
		}
		
		/////////////////////////////// ACTIONS ////////////////////////////////////////////
		////////////PAGES
		//afficher le menu principal
		private function showFirstMenu(evt :MouseEvent = null) :void {
			//afficher le container du menu
			menuContainer.visible = true;
			
			//masquer les pages du menu
			for (var i :int = 0; i < menuContainer.numChildren; i++) {
				var page :DisplayObject = menuContainer.getChildAt(i);
				page.visible = false;
			}
			
			//afficher le menu
			var menu :Sprite = menuContainer.getChildAt(0) as Sprite;
			menu.visible = true;
			menu.getChildAt(1).visible = true;
			menu.getChildAt(2).visible = false;
		}
		
		//afficher le menu niveaux
		private function showSecondMenu(evt :MouseEvent) :void {
			//afficher le container du menu
			menuContainer.visible = true;
			
			//masquer les pages du menu
			for (var i :int = 0; i < menuContainer.numChildren; i++) {
				var page :DisplayObject = menuContainer.getChildAt(i);
				page.visible = false;
			}
			
			//afficher le menu
			var menu :Sprite = menuContainer.getChildAt(0) as Sprite;
			menu.visible = true;
			menu.getChildAt(1).visible = false;
			menu.getChildAt(2).visible = true;
		}
		
		//afficher les regles
		private function showRules(evt :MouseEvent) :void {
			//afficher le container du menu
			menuContainer.visible = true;
			
			//masquer les pages du menu
			for (var i :int = 0; i < menuContainer.numChildren; i++) {
				var page :DisplayObject = menuContainer.getChildAt(i);
				page.visible = false;
			}
			
			//afficher le menu
			var rules :Sprite = menuContainer.getChildAt(1) as Sprite;
			rules.visible = true;
		}
		
		//afficher le jeu
		private function showGame(evt :MouseEvent) :void {
			menuContainer.visible = false;
			
			var btn :MovieClip = evt.currentTarget as MovieClip;
			
			initGame(btn.lvl);
		}
		
		////////////PERSO
		//deplacer le perso
		private function moveCharacter() :void {
			//deplacement horizontal
			if (moveLeft && ((character.x > 0 && stoned == 1) || (character.x < stage.stageWidth - character.width && stoned == -1))) {
				character.x -= moveH * stoned;
			}
			if (moveRight && ((character.x > 0 && stoned == -1) || (character.x < stage.stageWidth - character.width && stoned == 1))) {
				character.x += moveH * stoned;
			}
			
			//deplacement vertical
			var maxHeight :Number = stage.stageHeight / 3;
			//deplacer le perso
			if (character.y - pulse > maxHeight || pulse < 0) {
				character.y -= pulse;
			} else { //deplacer les plateaux
				hight += pulse;
				moveBkg();
				for (var i :int = 0; i < grid.length; i++) {
					var board :MovieClip = grid[i];
					board.y += pulse;
					//supprimer les plateaux en dehors du stage //ajouter des lignes
					if (board.y > stage.stageHeight) {
						if (boardsContainer.contains(board)) {
							boardsContainer.removeChild(board);
							grid.shift();
							createLines(1);
							i--;
						}
					}
				}
			}
		}
		
		//animer le perso
		private function animCharacter() :void {
			//anim du perso qui monte ou descend
			if (pulse > 0) {
				character.getChildAt(0).visible = true;
				character.getChildAt(1).visible = false;
				character.getChildAt(2).visible = false;
			} else {
				character.getChildAt(0).visible = false;
				character.getChildAt(1).visible = true;
				character.getChildAt(2).visible = false;
			}
			
			//anim du perso stoned
			if (stoned == -1) {
				character.getChildAt(0).visible = false;
				character.getChildAt(1).visible = false;
				character.getChildAt(2).visible = true;
				
				//incrementer le temps ou le perso est stone
				if (stoneTime < 240) {
					stoneTime ++;
				} else {
					stoneTime = 0;
					stoned = 1;
				}
			}
		}
		
		
		////////////PLATEAUX
		//ajouter des plateaux à la grille
		private function createLines(qty :int = 1) :void {
			var dy :Number = (grid.length <= 0) ? stage.stageHeight : grid[grid.length - 1].y; //posY du plateau
			var dx :Number; //position x du plateau
			var dt :Number; //valeur aleatoire 0/100 pour definir le type de plateau
			var type :int; //type du plateau
			var pctBoard :Array = levels[level].boardsPct; //proportions des plateaux
			var bonus :int; //bonus additionnel
			var pctBonus :Array = levels[level].bonusPct; //proportions des bonus
			
			//creer les lignes
			for (var i :int = 0; i < qty; i++) {
				//definir la position du plateau
				dy -= spacing;
				dx = Math.random() * (stage.stageWidth - 60);
				bonus = 0;
				
				//definir un nombre aleatoire entre 0 / 100 => type de plateau
				dt = Math.random() * 100;
				
				//choisir le type de plateforme en fonction de dt aleatoire
				switch (true) {
					//standard
					case dt < pctBoard[0] :
						type = 1;
						break;
					//impulse +
					case dt < pctBoard[0] + pctBoard[1] :
						type = 2;
						break;
					//impulse ++
					case dt < pctBoard[0] + pctBoard[1] + pctBoard[2] :
						type = 3;
						break;
					//destroy
					case dt < pctBoard[0] + pctBoard[1] + pctBoard[2] + pctBoard[3] :
						type = 4;
						break;
					//movable
					case dt <= pctBoard[0] + pctBoard[1] + pctBoard[2] +pctBoard[3] + pctBoard[4]:
						type = 5;
						break;
				}
				
				//ajouter un bonus
				if (type == 1) {
					//redefinir un nouveau nombre aléatoire => type de bonus
					dt = Math.random() * 100;
					
					//choisir le bonus en fonction de dt aléatoire
					switch(true) {
						case dt < pctBonus[0] :
							bonus = 1;
							break;
						case dt < pctBonus[0] + pctBonus[1] :
							bonus = 2;
							break;
					}
				}
				
				//creer / placer le plateau
				var b :MovieClip = createBoard(type, bonus);
				b.x = dx;
				b.y = dy;
				boardsContainer.addChild(b);
				grid.push(b);
			}
		}
		
		//creer plateau
		private function createBoard(type :int = 1, bonus :int = 0) :MovieClip {
			var color :uint; //couleur du plateau
			var impulse :Number = 1; //multiplicateur de l'impulsion
			var bmd :BitmapData; //image du plateau
			var bmdBonus :BitmapData; //image du bonus
			
			//creer le plateau
			var board :MovieClip = new MovieClip();
			
			//definir les valeurs du plateau selon le type
			switch(type) {
				case 0 :
					return null;
					break;
				//standard
				case 1 :
					color = 0xA8F791;
					bmd = bitmaps[4];
					break;
				// impulse +
				case 2 :
					color = 0x227A17;
					impulse = 2;
					bmd = bitmaps[5];
					break;
				//impulse ++
				case 3 :
					color = 0x1D3A26;
					impulse = 4;
					bmd = bitmaps[6];
					break;
				//destroy
				case 4 :
					color = 0xDADF47;
					bmd = bitmaps[7];
					break;
				//movable
				case 5 :
					color = 0xACB998;
					bmd = bitmaps[8];
					board.sens = 1;
					break;
				default :
					break;
			}
			
			//definir le bonus
			switch(bonus) {
				//bonus piece
				case 1 :
					bmdBonus = bitmaps[9];
					break;
				//bonus champi
				case 2 :
					bmdBonus = bitmaps[10];
					break;
				//pas de bonus
				default :
					bmdBonus = null;
					break;
			}
			
			//ajouter les images du plateau
			var bitmap :Bitmap = new Bitmap(bmd);
			var mask :Sprite = new Sprite();
			mask.graphics.beginFill(0xFFFFFF);
			mask.graphics.drawRect(0, 0, 60, 45);
			
			board.addChild(bitmap);
			board.addChild(mask);
			bitmap.mask = mask;
			
			//ajouter les images du bonus
			if (bmdBonus != null) {
				var bonusBitmap :Bitmap = new Bitmap(bmdBonus);
				board.addChild(bonusBitmap);
				
				bonusBitmap.x = 15;
				bonusBitmap.y = -10;
			}
			
			//attribuer les valeurs au plateau
			board.impulse = impulse;
			board.type = type;
			board.active = true;
			board.bonus = bonus;
			
			//renvoyer le plateau
			return board;
		}
		
		//definir le plateau en collision
		private function getCollisionBoard() :MovieClip {
			var cb :MovieClip; //plateau de collision
			
			//rechercher la collision
			if (pulse < 0) {
				for each (var board :MovieClip in grid) {
					var collider :DisplayObject = board.getChildAt(1); //collisionneur
					var isBonus :Boolean; //a un bonus
					
					//tester les collisions
					if (character.hitTestObject(collider) && character.y < board.y - character.height * .5 && board.active ) {
						
						//definir le plateau en collision
						cb = board;
						
						//replacer le perso
						character.y = board.y - character.height + 12;
						
						//redefinir l'impulsion
						pulse = board.impulse * normalPulse;
						
						//ajouter le bonus
						switch(board.bonus) {
							case 1 :
								bonus += 1000;
								isBonus = true;
								break;
							case 2 :
								stoneTime = 0;
								stoned = -1;
								isBonus = true;
								break;
							default :
								isBonus = false;
								break;
						}
						
						//masquer le bonus pris
						if (isBonus) {
							board.getChildAt(2).visible = false;
							board.bonus = 0;
						}
						
						//arreter la boucle si collision trouvée
						break;
					}
				}
			}
			
			//retourner le plateau
			return cb;
		}
		
		//effets additionnel sur plateaux
		private function addEffects(board :MovieClip) :void {
			//ajouter les effets au plateau en collision
			if (board != null) {
				//ajouter le plateau à la liste des plateaux à jouer
				if (board.type == 2 || board.type == 3 || board.type == 4) {
					playedBoards.push(board);
				}
				
				//supprimer le plateau cassable
				switch(board.type) {
					case 4 :
						board.active = false;
						break;
				}
			}
			
			//jouer les animations des plateaux
			for (var i :int = 0; i < playedBoards.length; i++) {
				var pb :MovieClip = playedBoards[i];
				var image :DisplayObject = pb.getChildAt(0);
				if (image.x > - (image.width - 61)) {
					image.x -= 60;
				} else {
					if(pb.type != 4) image.x = 0;
					playedBoards.splice(i, 1);
					i --;
				}
			}
			
			//ajouter les effets additionnels des plateaux selon son type
			for each(var b :MovieClip in grid) {
				switch(b.type) {
					case 5 :
						moveBoard(b);
						break;
				}
			}
		}
		
		//deplacer le plateau
		private function moveBoard(b :MovieClip) :void{
			//deplacer le plateau
			b.x += b.sens;
			
			//animer le plateau
			var image :DisplayObject = b.getChildAt(0);
			if (image.x > - (image.width - 61)) {
				image.x -= 60;
			} else {
				image.x = 0;
			}
			
			//inverser le sens quand touche les extremités
			if (b.x <= 0 || b.x >= stage.stageWidth) b.sens *= -1;
			
			//replacer / orienter correctement le plateau aux extremités
			if (b.x <= 0) b.x += 60;
			if (b.x >= stage.stageWidth) b.x = stage.stageWidth - 60;
			b.scaleX = -b.sens;
		}
		
		
		////////////BACKGROUND
		//deplacer le fond
		private function moveBkg() :void {
			//deplacer le fond
			for (var i :int = 0; i < bkgContainer.numChildren; i++) {
				//deplacer le bitmpa du fond
				var bkg :DisplayObject = bkgContainer.getChildAt(i);
				bkg.y += pulse;
				//supprimer le bitmap en dehors du stage
				if(bkg.y > stage.stageHeight) bkgContainer.removeChild(bkg);
			}
			//ajouter une nouvelle image
			bkg = bkgContainer.getChildAt(0);
			if (bkg.y > 0 && bkgContainer.numChildren < 2) {
				var bm :Bitmap = new Bitmap(bitmaps[3]);
				bm.y = bkg.y - bm.height;
				bkgContainer.addChild(bm);
			}
		}
		
		
		////////////GAME
		//gameOver
		private function gameOver() :void {
			//supprimer l'update
			removeEventListener(Event.ENTER_FRAME, update);
			
			//masquer le jeu
			gameContainer.visible = false;
			
			//afficher le container du menu
			menuContainer.visible = true;
			
			//masquer les pages du menu
			for (var i :int = 0; i < menuContainer.numChildren; i++) {
				var page :DisplayObject = menuContainer.getChildAt(i);
				page.visible = false;
			}
			
			//afficher le menu
			var loose :Sprite = menuContainer.getChildAt(2) as Sprite;
			loose.visible = true;
			
			//afficher les infos
			var scoreTf :TextField = loose.getChildAt(1) as TextField;
			scoreTf.text = "SCORE :" + score;
			scoreTf.appendText ("\n HIGHTSCORE :" + hightscore);
		}
		
		//aller au level
		private function setLevel(lvl :int = 0) :void {
			//si le level demandé est superieur au nombre de levels ne pas modifier
			if (lvl >= levels.length || lvl < 0) return;
			
			//definir le level
			level = lvl;
			
			//attribuer les valeurs du level
			var lvlObj :Object = levels[level];
			spacing = lvlObj.spacing
			gravity = lvlObj.gravity;
			moveH = lvlObj.moveH;
			normalPulse = lvlObj.pulse;
		}
		
		//afficher le score
		private function drawScore() :void {
			//definir le score
			var newscore :Number = hight + stage.stageHeight - character.y + bonus;
			if (newscore > score) score = newscore;
			
			//definir le hightscore
			if (score > hightscore) hightscore = score;
			
			//afficher le score
			var scoreTf :TextField = infoContainer.getChildByName("score") as TextField;
			scoreTf.text = "SCORE :" + score.toString();
		}
		
		////////////////////////////// EVENTS //////////////////////////////////////////////
		//presser la touche
		private function pressKey(evt :KeyboardEvent) :void {
			var key :uint = evt.keyCode;
			
			switch(key) {
				case Keyboard.LEFT :
					moveLeft = true;
					break;
				case Keyboard.RIGHT :
					moveRight = true;
					break;
				case Keyboard.NUMPAD_0 :
					//initGame();
					break;
			}
		}
		
		//relacher la touche
		private function releaseKey(evt :KeyboardEvent) :void {
			var key :uint = evt.keyCode;
			
			switch(key) {
				case Keyboard.LEFT :
					moveLeft = false;
					break;
				case Keyboard.RIGHT :
					moveRight = false;
					break;
			}
		}
		
		//update
		private function update(evt :Event) :void {
			//definir le level
			if (score >= levels[level].score) {
				//setLevel(level + 1);
			}
			
			//animer le perso
			animCharacter();
			
			//deplacer le perso
			moveCharacter();
			
			//rebondir sur le plateau
			var collisionBoard :MovieClip = getCollisionBoard();
			
			//effets additionnel des plateaux
			addEffects(collisionBoard);
			
			//diminuer l'impulsion
			if (pulse - gravity > - character.height * .5) pulse -= gravity;
			
			//afficher le score
			drawScore();
			
			//game Over
			if (character.y > stage.stageHeight) gameOver();
		}
		
		
	}

}