module Main exposing (Candidate, InsertPosition(..), Model, Msg(..), divStyle, init, insertBefore, main, moveTo, update, view, viewDiv)

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


divStyle =
    [ style "border" "1px solid black"
    , style "padding" "50px"
    , style "text-align" "center"
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
    div [] (Array.indexedMap (viewDiv srcId dropIdx position) model.ranks |> Array.toList)


viewDiv : Maybe Int -> Maybe Int -> Maybe DragDrop.Position -> Int -> Candidate -> Html Msg
viewDiv srcIdx dropIdx droppablePosition idx candidate =
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
        (divStyle
            ++ highlight
            ++ (if srcIdx /= Just idx then
                    DragDrop.droppable DragDropMsg idx

                else
                    []
               )
            ++ DragDrop.draggable DragDropMsg idx
        )
        [ span [] [ text candidateName ] ]


main =
    Browser.sandbox
        { init = init
        , update = update
        , view = view
        }
