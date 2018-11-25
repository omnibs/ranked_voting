module Main exposing (Candidate, InsertPosition(..), Model, Msg(..), cardStyle, init, insertBefore, main, moveTo, update, view, viewCard)

import Array as Array exposing (Array(..))
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html5.DragDrop as DragDrop


type Id
    = Id Int


type alias Candidate =
    { id : Id, name : String }


intId : Id -> Int
intId (Id i) =
    i


type alias Model =
    { ranks : Array Candidate

    -- , unranked : Array Candidate
    , dragDrop : DragDrop.Model Int Int
    }


type Msg
    = DragDropMsg (DragDrop.Msg Int Int)


init : Model
init =
    { ranks =
        Array.fromList
            [ { id = Id 1, name = "Joao" }
            , { id = Id 2, name = "Jose" }
            , { id = Id 3, name = "Jorel" }
            ]
    , dragDrop = DragDrop.init
    }


type InsertPosition
    = Above
    | Below


insertPosition : Int -> Int -> InsertPosition
insertPosition y height =
    if toFloat y < toFloat height * 0.8 then
        Above

    else
        Below


update : Msg -> Model -> Model
update msg model =
    case msg of
        DragDropMsg msg_ ->
            let
                ( dragDropModel, dragDropEndResult ) =
                    DragDrop.update msg_ model.dragDrop
            in
            case dragDropEndResult of
                Nothing ->
                    { model | dragDrop = dragDropModel }

                Just ( dragIdx, dropIdx, pos ) ->
                    case insertPosition pos.y pos.height of
                        Above ->
                            { model | dragDrop = dragDropModel, ranks = moveTo model.ranks dragIdx dropIdx }

                        Below ->
                            { model | dragDrop = dragDropModel, ranks = moveTo model.ranks dragIdx (dropIdx + 1) }


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
            , div listStyle (Array.indexedMap (viewCard srcId dropIdx position) model.ranks |> Array.toList)
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


viewCard : Maybe Int -> Maybe Int -> Maybe DragDrop.Position -> Int -> Candidate -> Html Msg
viewCard srcIdx dropIdx droppablePosition idx candidate =
    let
        highlight =
            if dropIdx |> Maybe.map ((==) idx) |> Maybe.withDefault False then
                case droppablePosition of
                    Nothing ->
                        []

                    Just pos ->
                        case insertPosition pos.y pos.height of
                            Above ->
                                [ style "background-color" "cyan" ]

                            Below ->
                                [ style "background-color" "magenta" ]

            else
                []

        candidateName =
            candidate.name ++ " (" ++ String.fromInt (idx + 1) ++ ")"
    in
    div
        (cardStyle
            ++ highlight
            ++ (if srcIdx /= Just idx then
                    DragDrop.droppable DragDropMsg idx

                else
                    []
               )
            ++ DragDrop.draggable DragDropMsg idx
        )
        [ div cardDetailsStyle
            [ span cardNameStyle [ text candidateName ]
            ]
        ]


main =
    Browser.sandbox
        { init = init
        , update = update
        , view = view
        }
