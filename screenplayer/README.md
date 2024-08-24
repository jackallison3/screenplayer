# ScreenPlayer for Godot

## Description

The ScreenPlayer plugin for Godot 4 allows you to import screenplays saved in (OpenScreenplayFormat)[https://github.com/OpenScreenplayFormat/osf-sdk] into Godot and easily create visual novel style cutscenes.

## Installation
* Download the `screenplayer` folder from this repo.
* Copy the folder to the `addons` folder in your Godot 4 project.
* In Godot, navigate to `Project > Project Settings > Plugins` and enable ScreenPlayer.

## Usage

### Preparing your screenplay
* Create the screenplay for your scene using (Fade In)[https://www.fadeinpro.com/], or any screenplay software that supports export to OpenScreenplayFormat. Export your script as `XML (Open Screenplay Format)`.
	* Note: The free trial of (Fade In)[https://www.fadeinpro.com] allows you to create scripts and export to Open Screenplay Format XML without restriction.
	* If you wish to use scene numbers to specify a scene in ScreenPlayer, make sure to enable scene numbers in Fade in by navigating to `Production > Scene Numbering...` and then lock scene numbers by navigating to `Production > Lock Scene Numbers`. **Using a scene number in ScreenPlayer will not work unless scene numbers are locked prior to export**.
* Import your exported XML file into your Godot project.

### Loading your screenplay
* In your Godot scene where you want the cutscene, add the `ScreenPlayer` node.
* The `ScreenPlayer` node will automatically create a child `ScreenplayReader` node. Load your XML screenplay into `Script File`.
* With your script file loaded, choose whether you want to load a specific scene by scene number. Examine the prepopulated `Raw Scene` array to ensure you have loaded the correct scene.
* With the script loaded and scene number selected (if desired), click the checkbox for `Script Locked`. The `ScreenplayReader` node will be removed, and your scene will be populated with locations and characters from your script along with a `ScenePlayer` node.
* **Do not change the structure of the populated nodes, or your ScenePlayer will break**.

### Preparing your locations
* Under the `Locations` node, a `CanvasLayer` will have populated for each of your locations with a `LocationCanvasModulate` child. Add the background element for each of your scenes as a child to the `CanvasLayer` named for that location. You can instantiate another scene as a child, or add a `TextureRect`, or `ColorRect`, or anything you'd like as the backdrop for that scene. **Just make sure it is added as a child to the `CanvasLayer` named for that location.

### Preparing your characters
* Under the `Characters` node, an `AnimatedSprite2D` will have populated for each character in your script, with a `CharacterAnimationPlayer` child.
* For each `AnimatedSprite2D`, you will find its `AnimationPlayer` prepopulated with a blank animation for each parenthetical (called `states` in ScreenPlayer) in the script, along with a `default` animation. Load frames for each of these animations.
	* When you play your scene, if a piece of dialogue does not have a parenthetical, your character will play its `default` animation. Otherwise, it will play the animation that matches the state.
* For the child `CharacterAnimationPlayer`, you will find animations prepopulated for each state, along with a `transition` animation. Create a `transition` animation with the first frame being the character's inactive (off-stage) position, and the final frame being the character's active (on-stage) position.
	* When you play your scene, this animation will `play` when your characters moves on-stage, and `play-backward` when your character moves off-stage.
	* The animations for the other states do not necessarily need to be created. These are created in case you need anything other than the sprite frames changed for a specific state. For example: adding a sound effect when a character goes into "laughs" state.

### Preparing the ScenePlayer
* With your Locations and Characters added, you can adjust the settings for the ScenePlayer.

#### ScenePlayer Settings

**Scene Data**
* `Scene Data`: An array of each moment of your loaded scene. If you would like to make manual adjustments to your scene, find the corresponding entry in the array and adjust. *Be careful: Some manual adjustments, eg. to a character's name, may cause your scene to break*.
	* If you would like to ensure a character is on-screen during a specific action line (when `Transition Characters Offstage When Inactive` is enabled), find the action line and add a new key with key: `"character"` and with your character's name (in ALL-CAPS, matching the name of the node) as the value.
* `Characters`: A Dictionary containing your characters with their name as it will appear in-game in the dialogue box. If you would like to change how the name is displayed (eg. "Name" instead of "NAME"), change the value for key `"name"` here for the character.

**ScenePlayer Settings**

With your Locations and Characters prepared, your cutscene will be ready to play. If `Play On Ready` is enabled, you can simply start and view your scene, or change the below settings to modify how your `ScenePlayer` functions.

* `Dialogue Box Scene`: A reference to the Dialogue Box that will be used when playing your scene. If left empty, this will default to the default dialogue box found in `addons/screenplayer/dialogue_box/dialogue_box.tscn`.
	* If you create your own Dialogue box, ensure that it has the following variables pointing to the correct nodes:
		* `dialogue_label`: `RichTextLabel`
		* `name_label`: `RichTextLabel`
		* `next_icon`: `Control`
		* `name_panel_container`: `PanelContainer`
* `Play On Ready`: Enable to have the your cutscene start playing as soon as the scene is loaded.
	* Otherwise, call to `play_scene()` in `ScenePlayer` to start the cutscene.
* `Next Button Mapping`: String containing the button mapping you would like to use for the "Next" button action. Defaults to `ui_accept`.
* `Transition Characters Offstage When Inactive`: Enable to have characters transition off when they are not the active speaker. Disable to have characters stay onstage when not speaking.
* `Fade Speed`: The speed * delta at which locations and characters will fade in and out.
* `Dialogue Box Fade Speed`: The speed * delta at which the Dialogue Box and Name Panel will fade in and out.
* `Characters Start Onstage`: Enable to have all characters in scene onstage when the cutscene begins. Disable and they will enter when active.
* `Free Screen Player on Scene End`: Enable to have `ScreenPlayer` `queue_free()` when the scene is complete. *Warning: This will cause a crash if ScreenPlayer is the root node.*

## Issues/Known Bugs
* Right now, ScreenPlayer does not handle **bold**, *italics*, and underlines in screenplay XML. I plan to fix this next, but for now it may cause lines with bold or italicized words to be truncated.