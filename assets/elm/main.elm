module Main exposing (Candidate, InsertPosition(..), Model, Msg(..), divStyle, find, init, insertBefore, main, moveTo, update, view, viewDiv)

import Array as Array exposing (Array(..))
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html5.DragDrop as DragDrop

type Id = Id Int

type alias Candidate =
    { id : Id, name : String }

intId : Id -> Int
intId (Id i) = i

type alias Model =
    { ranks : Array Candidate

    -- , unranked : Array Candidate
    , dragDrop : DragDrop.Model Id Int
    }


type Msg
    = DragDropMsg (DragDrop.Msg Id Int)


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


update : Msg -> Model -> Model
update msg model =
    case msg of
        DragDropMsg msg_ ->
            let
                ( model_, result ) =
                    DragDrop.update msg_ model.dragDrop
            in
            case result of
                Nothing ->
                    { model | dragDrop = model_ }

                Just ( dragId, dropId, pos ) ->
                    let
                        insertAt =
                            if pos.y < pos.height // 2 then
                                Above
                            else
                                Below
                    in
                    case insertAt of
                        Above ->
                            { model | dragDrop = model_, ranks = moveTo model.ranks dragId dropId }

                        Below ->
                            { model | dragDrop = model_, ranks = moveTo model.ranks dragId (dropId + 1) }


moveTo : Array Candidate -> Id -> Int -> Array Candidate
moveTo ranks srcId destPos =
    case find srcId ranks of
        Nothing ->
            ranks

        Just src ->
            if destPos >= (Array.length ranks - 1) then
                ranks
                    |> Array.filter (\{ id } -> id /= srcId)
                    |> Array.push src
            else
                ranks
                    |> Array.indexedMap (\i a -> ( i, a ))
                    |> Array.foldr (insertBefore src destPos) []
                    |> Array.fromList


find : a -> Array { r | id : a } -> Maybe { r | id : a }
find fid ranks =
    Array.filter (\{ id } -> id == fid) ranks
        |> Array.get 0


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


viewDiv : Maybe Id -> Maybe Int -> Maybe DragDrop.Position -> Int -> Candidate -> Html Msg
viewDiv srcId dropIdx droppablePosition idx candidate =
    let
        highlight =
            if dropIdx |> Maybe.map ((==) idx) |> Maybe.withDefault False then
                case droppablePosition of
                    Nothing ->
                        []

                    Just pos ->
                        if pos.y < pos.height // 2 then
                            [ style "background-color" "cyan" ]
                        else
                            [ style "background-color" "magenta" ]
            else
                []
    in
    div
        (divStyle
            ++ highlight
            ++ (if srcId /= Just candidate.id then
                    DragDrop.droppable DragDropMsg idx
                else
                    []
               )
            ++ DragDrop.draggable DragDropMsg candidate.id
        )
        [ span [] [ text candidate.name ]
        , text (String.fromInt (Maybe.withDefault -1 (Maybe.map intId srcId)))
        , text (String.fromInt (Maybe.withDefault -1 dropIdx))
        , text (String.fromInt idx)
        ]


main =
    Browser.sandbox
        { init = init
        , update = update
        , view = view
        }
