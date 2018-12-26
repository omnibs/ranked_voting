module Main exposing (Candidate, InsertPosition(..), Model, Msg(..), cardStyle, init, insertBefore, main, moveTo, update, view, viewCard)

import Array as Array exposing (Array(..))
import Browser
import Debug
import Html exposing (..)
import Html.Attributes exposing (..)
import Html5.DragDrop as DragDrop
import Keyboard exposing (RawKey)


type Id
    = Id Int


type alias Candidate =
    { id : Id, name : String }


intId : Id -> Int
intId (Id i) =
    i


type alias Model =
    { ranks : Array Candidate
    , dragDrop : DragDrop.Model Int Int
    , keyboardCursor : CursorState Int
    }


type CursorState a
    = Off
    | On a
    | Moving a


type Msg
    = DragDropMsg (DragDrop.Msg Int Int)
    | KeyUp RawKey
    | KeyDown RawKey


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Keyboard.downs KeyDown
        , Keyboard.ups KeyUp

        -- , windowBlurs ClearKeys
        ]


init : ( Model, Cmd Msg )
init =
    ( { ranks =
            Array.fromList
                [ { id = Id 1, name = "Alice" }
                , { id = Id 2, name = "Bob" }
                , { id = Id 3, name = "Carol" }
                ]
      , dragDrop = DragDrop.init
      , keyboardCursor = Off
      }
    , Cmd.none
    )


type InsertPosition
    = Above
    | Below


insertPosition : Int -> Int -> InsertPosition
insertPosition y height =
    if toFloat y < toFloat height * 0.5 then
        Above
    else
        Below


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DragDropMsg msg_ ->
            let
                ( dragDropModel, dragDropEndResult ) =
                    DragDrop.update msg_ model.dragDrop
            in
            case dragDropEndResult of
                Nothing ->
                    ( { model | dragDrop = dragDropModel }, Cmd.none )

                Just ( dragIdx, dropIdx, pos ) ->
                    case insertPosition pos.y pos.height of
                        Above ->
                            ( { model | dragDrop = dragDropModel, ranks = moveTo model.ranks dragIdx dropIdx }, Cmd.none )

                        Below ->
                            ( { model | dragDrop = dragDropModel, ranks = moveTo model.ranks dragIdx (dropIdx + 1) }, Cmd.none )

        KeyUp rawKey ->
            case Keyboard.modifierKey rawKey of
                Nothing ->
                    ( model, Cmd.none )

                Just Keyboard.Shift ->
                    ( { model | keyboardCursor = stopMoving model.keyboardCursor }, Cmd.none )

                Just key ->
                    Debug.log (Debug.toString key) ( model, Cmd.none )

        KeyDown rawKey ->
            case Keyboard.oneOf [ Keyboard.navigationKey, Keyboard.modifierKey ] rawKey of
                Nothing ->
                    ( model, Cmd.none )

                Just Keyboard.ArrowUp ->
                    let
                        ( movement, cursor ) =
                            keyUp model.keyboardCursor

                        ranks =
                            case movement of
                                Nothing ->
                                    model.ranks

                                Just ( src, dst ) ->
                                    moveTo model.ranks src dst
                    in
                    ( { model | keyboardCursor = cursor, ranks = ranks }, Cmd.none )

                Just Keyboard.ArrowDown ->
                    let
                        ( movement, cursor ) =
                            keyDown model.keyboardCursor (Array.length model.ranks)

                        ranks =
                            case movement of
                                Nothing ->
                                    model.ranks

                                Just ( src, dst ) ->
                                    -- dst + 1 because we move it below the next position
                                    moveTo model.ranks src (dst + 1)
                    in
                    ( { model | keyboardCursor = cursor, ranks = ranks }, Cmd.none )

                Just Keyboard.Shift ->
                    ( { model | keyboardCursor = startMoving model.keyboardCursor }, Cmd.none )

                Just key ->
                    Debug.log (Debug.toString key) ( model, Cmd.none )


startMoving : CursorState Int -> CursorState Int
startMoving state =
    case state of
        Off ->
            Moving 0

        On n ->
            Moving n

        Moving n ->
            Moving n


stopMoving : CursorState Int -> CursorState Int
stopMoving state =
    case state of
        Off ->
            Off

        On n ->
            On n

        Moving n ->
            On n


keyUp : CursorState Int -> ( Maybe ( Int, Int ), CursorState Int )
keyUp maybeCurrentIndex =
    case maybeCurrentIndex of
        Off ->
            ( Nothing, On 0 )

        On 0 ->
            ( Nothing, On 0 )

        On n ->
            ( Nothing, On (n - 1) )

        Moving 0 ->
            ( Nothing, Moving 0 )

        Moving n ->
            ( Just ( n, n - 1 ), Moving (n - 1) )


keyDown : CursorState Int -> Int -> ( Maybe ( Int, Int ), CursorState Int )
keyDown maybeCurrentIndex max =
    case maybeCurrentIndex of
        Off ->
            ( Nothing, On 0 )

        On n ->
            if n >= max then
                ( Nothing, On max )
            else
                ( Nothing, On (n + 1) )

        Moving n ->
            if n >= max then
                ( Nothing, On max )
            else
                ( Just ( n, n + 1 ), Moving (n + 1) )


moveTo : Array a -> Int -> Int -> Array a
moveTo ranks srcIdx dstIdx =
    case Array.get srcIdx ranks of
        Nothing ->
            ranks

        Just src ->
            if dstIdx >= Array.length ranks then
                ranks
                    |> Array.indexedMap (\i a -> ( i, a ))
                    |> Array.filter (\( i, a ) -> i /= srcIdx)
                    |> Array.map Tuple.second
                    |> Array.push src
            else
                ranks
                    |> Array.indexedMap (\i a -> ( i, a ))
                    |> Array.foldr (insertBefore src dstIdx) []
                    |> Array.fromList


insertBefore : a -> Int -> ( Int, a ) -> List a -> List a
insertBefore src destIdx ( idx, curr ) acc =
    if curr == src then
        -- check for case where we're reinserting in the same position
        if destIdx == idx then
            curr :: acc
        else
            acc
    else if idx == destIdx then
        src :: curr :: acc
    else
        curr :: acc


columnStyle =
    [ style "width" "300px"
    , style "margin" "0 4px"
    , style "height" "100%"
    , style "box-sizing" "border-box"
    , style "display" "inline-block"
    , style "vertical-align" "top"
    , style "white-space" "nowrap"
    ]


columnContent =
    [ style "background-color" "#dfe3e6"
    , style "border-radius" "3px"
    , style "box-sizing" "border-box"
    , style "display" "flex"
    , style "flex-direction" "column"
    , style "max-height" "100%"
    , style "position" "relative"
    , style "white-space" "normal"
    ]


listHeader =
    [ style "flex" "0 0 auto"
    , style "padding" "10px 8px 8px"
    , style "position" "relative"
    , style "min-height" "20px"
    , style "text-align" "center"
    , style "font-weight" "bold"
    , style "color" "#17394d"
    ]


listStyle =
    [ style "flex" "1 1 auto"
    , style "margin-bottom" "0"
    , style "overflow-y" "auto"
    , style "overflow-x" "hidden"
    , style "margin" "0 4px"
    , style "padding" "0 4px"
    , style "z-index" "1"
    , style "min-height" "0"
    ]


view : Model -> Html Msg
view model =
    let
        srcId =
            DragDrop.getDragId model.dragDrop

        dropIdx =
            DragDrop.getDropId model.dragDrop

        position =
            DragDrop.getDroppablePosition model.dragDrop
    in
    div columnStyle
        [ div columnContent
            [ div listHeader [ text "Candidates" ]
            , div listStyle (Array.indexedMap (viewCard srcId dropIdx position model.keyboardCursor) model.ranks |> Array.toList)
            ]
        ]


cardStyle =
    [ style "border-radius" "3px"
    , style "background-color" "#fff"
    , style "box-shadow" "0 1px 0 rgba(9,45,66,.25)"
    , style "cursor" "pointer"
    , style "margin-bottom" "8px"
    , style "max-width" "300px"
    , style "min-height" "20px"
    , style "position" "relative"
    , style "text-decoration" "none"
    , style "z-index" "0"
    ]


cardDetailsStyle =
    [ style "overflow" "hidden"
    , style "padding" "10px 10px 5px"
    , style "position" "relative"
    , style "z-index" "10"
    ]


cardNameStyle =
    [ style "clear" "both"
    , style "display" "block"
    , style "margin" "0 0 4px"
    , style "overflow" "hidden"
    , style "text-decoration" "none"
    , style "word-wrap" "break-word"
    , style "color" "#17394d"
    ]


fadeBottomStyle =
    [ style "background-image" "linear-gradient(to bottom, rgba(223, 227, 230, 0), rgba(223, 227, 230, 0.9) 100%)"
    , style "box-shadow" "none"
    ]


fadeTopStyle =
    [ style "background-image" "linear-gradient(to bottom, rgba(223, 227, 230, 0.9), rgba(223, 227, 230, 0) 100%)"
    ]


type CardState
    = Plain
    | Dragging
    | DropIsNext
    | DropIsPrev
    | CursorOn
    | CursorMoving


cardState : Int -> Maybe Int -> Maybe Int -> Maybe InsertPosition -> CursorState Int -> CardState
cardState idx dragIdx dropIdx maybeInsertPosition cursorState =
    case maybeInsertPosition of
        Nothing ->
            case cursorState of
                Off ->
                    Plain

                On n ->
                    if n == idx then
                        CursorOn
                    else
                        Plain

                Moving n ->
                    if n == idx then
                        CursorMoving
                    else
                        Plain

        Just Above ->
            if Just idx == dragIdx then
                Dragging
            else if Just idx == dropIdx then
                DropIsPrev
            else if Just (idx + 1) == dropIdx then
                DropIsNext
            else
                Plain

        Just Below ->
            if Just idx == dragIdx then
                Dragging
            else if Just idx == dropIdx then
                DropIsNext
            else if Just (idx - 1) == dropIdx then
                DropIsPrev
            else
                Plain


cardStyleFor : CardState -> List (Attribute msg)
cardStyleFor state =
    case state of
        Plain ->
            cardStyle

        Dragging ->
            cardStyle ++ [ style "background-color" "rgba(255,255,255,0.37)" ]

        DropIsPrev ->
            cardStyle ++ fadeTopStyle

        DropIsNext ->
            cardStyle ++ fadeBottomStyle

        CursorOn ->
            cardStyle ++ [ style "border" "3px solid blue" ]

        CursorMoving ->
            cardStyle ++ [ style "border" "3px solid purple" ]


viewCard : Maybe Int -> Maybe Int -> Maybe DragDrop.Position -> CursorState Int -> Int -> Candidate -> Html Msg
viewCard dragIdx dropIdx droppablePosition cursorState idx candidate =
    let
        position =
            droppablePosition
                |> Maybe.map (\pos -> insertPosition pos.y pos.height)

        state =
            cardState idx dragIdx dropIdx position cursorState

        candidateName =
            candidate.name
    in
    div
        ([ style "overflow" "auto" ]
            ++ (if dragIdx /= Just idx then
                    DragDrop.droppable DragDropMsg idx
                else
                    []
               )
            ++ DragDrop.draggable DragDropMsg
                idx
        )
        [ div
            (cardStyleFor state)
            [ div cardDetailsStyle
                [ span cardNameStyle [ text candidateName ]
                ]
            ]
        ]


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
