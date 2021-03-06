module Root exposing (..)

import List.Extra
import Json.Decode as Json
import Time exposing (Time)
import Animation
import Navigation
import Routing


--

import Library
import Channel
import Receiver
import Rendition
import ID
import Input
import Utils.Touch
import Notification
import State
import Msg exposing (Msg)
import Settings
import Animation


type alias Model =
    { connected : Bool
    , channels : List Channel.Model
    , receivers : List Receiver.Model
    , showAddChannel : Bool
    , newChannelInput : Input.Model
    , activeChannelId : Maybe ID.Channel
    , listMode : State.ChannelListMode
    , windowInnerWidth : Int
    , showPlaylistAndLibrary : Bool
    , library : Library.Model
    , touches : Utils.Touch.Model
    , startTime : Time
    , animationTime : Time
    , notifications : List (Notification.Model Msg)
    , showHubControl : Bool
    , controlChannel : Bool
    , controlReceiver : Bool
    , viewMode : State.ViewMode
    , showChannelControl : Bool
    , savedState : Maybe SavedState
    , configuration : Configuration
    , viewAnimations : ViewAnimations
    , forcePress : Bool
    }


type alias ViewAnimations =
    { revealChannelList : Animation.Animation
    , revealChannelControl : Animation.Animation
    }


type alias Startup =
    { time : Time
    , windowInnerWidth : Int
    , savedState : Maybe SavedState
    }


type alias SavedState =
    { activeChannelId : ID.Channel
    , viewMode : State.ViewModeString
    }


type alias ReceiverStatusEvent =
    { channelId : String
    , receiverId : String
    }


type alias ChannelStatusEvent =
    { channelId : String
    , status : String
    }


type alias Configuration =
    { settings : Maybe Settings.Model
    , viewMode : Settings.ViewMode
    , showAddChannelInput : Bool
    , addChannelInput : Input.Model
    }


activeChannel : Model -> Maybe Channel.Model
activeChannel model =
    case model.activeChannelId of
        Nothing ->
            Nothing

        Just id ->
            List.Extra.find (\c -> c.id == id) model.channels


playlistVisible : Model -> Bool
playlistVisible model =
    case model.showPlaylistAndLibrary of
        True ->
            True

        False ->
            case model.listMode of
                State.LibraryMode ->
                    False

                State.PlaylistMode ->
                    True


gotoDefaultChannel : Model -> Cmd Msg
gotoDefaultChannel model =
    case model.activeChannelId of
        Just id ->
            let
                activeChannelExists =
                    List.any (\c -> c.id == id) model.channels
            in
                if activeChannelExists then
                    Cmd.none
                else
                    gotoDefaultChannel { model | activeChannelId = Nothing }

        Nothing ->
            let
                defaultChannelId =
                    Maybe.map (\channel -> channel.id) (List.head model.channels)
            in
                case defaultChannelId of
                    Nothing ->
                        Cmd.none

                    Just id ->
                        Navigation.newUrl (Routing.channelLocation id)
