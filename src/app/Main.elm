port module Main exposing (..)

import AppTranslation exposing (..)
import Html exposing (Attribute, Html, a, div, span, text, table, td, tr)
import Html.Attributes exposing (attribute, class, href, target)
import Html.Events exposing (on, onClick, onMouseLeave)
import Json.Decode exposing (Decoder, at, string)
import RemoteData exposing (RemoteData)


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias ProofreadComment =
    { start : Int
    , end : Int
    , url : String
    , hint : { description : String, name : String }
    }


type alias ProofreadResult =
    { status : String
    , score : String
    , fragments : List ProofreadComment
    }


type alias Model =
    { selectedText : String
    , proofreadResult : RemoteData String ProofreadResult
    , activeCommentId : Maybe Int
    , currentLanguage : Language
    }


type alias Flags =
    { language : String
    }



-- INIT


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        language =
            case String.toLower flags.language of
                "ru-ru" ->
                    Russian

                _ ->
                    English
    in
    ( Model "" RemoteData.NotAsked Nothing language, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ suggestions Suggest
        , textChanged TextChanged
        , externalError Error
        ]



-- PORTS


port check : String -> Cmd msg


port suggestions : (ProofreadResult -> msg) -> Sub msg


port textChanged : (String -> msg) -> Sub msg


port externalError : (String -> msg) -> Sub msg



-- UPDATE


type Msg
    = Suggest ProofreadResult
    | TextChanged String
    | Error String
    | SetActiveComment String
    | ResetActiveComment


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TextChanged newText ->
            case newText of
                "" ->
                    ( { model | selectedText = newText, proofreadResult = RemoteData.NotAsked }, Cmd.none )

                _ ->
                    ( { model | selectedText = newText, proofreadResult = RemoteData.Loading }, check newText )

        Suggest suggestion ->
            ( { model | proofreadResult = RemoteData.Success suggestion }, Cmd.none )

        Error error ->
            ( { model | proofreadResult = RemoteData.Failure error }, Cmd.none )

        SetActiveComment commentId ->
            let
                result =
                    String.toInt commentId
            in
            case result of
                Ok activeCommentId ->
                    ( { model | activeCommentId = Just activeCommentId }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        ResetActiveComment ->
            ( { model | activeCommentId = Nothing }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    case model.proofreadResult of
        RemoteData.NotAsked ->
            composeView [ viewTextPlaceholder <| translate model.currentLanguage PlaceholderText ] [ viewEmptySection, viewHelpSection model ]

        RemoteData.Loading ->
            composeView [ viewTextSection model.selectedText [] ] [ viewLoadingSection, viewHelpSection model ]

        RemoteData.Failure error ->
            composeView [ viewTextPlaceholder <| translate model.currentLanguage PlaceholderText ] [ viewErrorSection model, viewHelpSection model ]

        RemoteData.Success result ->
            let
                additionalSection =
                    case model.activeCommentId of
                        Just commentId ->
                            viewCommentSection result.fragments model.activeCommentId

                        Nothing ->
                            viewSummarySection model.currentLanguage result
            in
            composeView [ viewTextSection model.selectedText result.fragments ] [ additionalSection, viewHelpSection model ]


composeView : List (Html Msg) -> List (Html Msg) -> Html Msg
composeView textSection additionalInfoSection =
    div [ class "addin" ]
        [ div [ class "text-section section" ] textSection
        , viewDivider
        , div [ class "additional-info-section section" ] additionalInfoSection
        ]


viewDivider : Html msg
viewDivider =
    div [ class "divider" ] []


viewEmptySection : Html msg
viewEmptySection =
    div [ class "empty-section" ] []


viewLoadingSection : Html msg
viewLoadingSection =
    div [ class "empty-section spinner" ] []


viewErrorSection : Model -> Html msg
viewErrorSection model =
    div [ class "error-section" ] [ text <| translate model.currentLanguage GlvrdNotAvailable ]


viewTextSection : String -> List ProofreadComment -> Html Msg
viewTextSection selectedText comments =
    div []
        (viewCommentedText
            selectedText
            comments
            0
        )


viewTextPlaceholder : String -> Html msg
viewTextPlaceholder placeholderText =
    div [ class "placeholder-text" ] [ text placeholderText ]


viewHelpSection : Model -> Html msg
viewHelpSection model =
    div [ class "help-section" ]
        [ div []
            [ a [ href <| translate model.currentLanguage OpenInGlvrdUrl, target "_blank", class "link-text" ] [ text <| translate model.currentLanguage OpenInGlvrdText ]
            ]
        , div []
            [ a [ href <| translate model.currentLanguage AboutUrl, target "_blank", class "link-text" ] [ text <| translate model.currentLanguage AboutText ]
            ]
        ]


viewCommentedText : String -> List ProofreadComment -> Int -> List (Html Msg)
viewCommentedText commentedText comments lastProcessedIndex =
    case comments of
        comment :: restComments ->
            let
                leftText =
                    String.slice lastProcessedIndex comment.start commentedText

                commentText =
                    String.slice comment.start comment.end commentedText

                newLastProcessedIndex =
                    comment.end
            in
            span [] [ text leftText ]
                :: span
                    [ class "commented-text"
                    , attribute "id" (toString comment.start)
                    , handleOnMouseEnter SetActiveComment
                    , handleOnMouseLeave ResetActiveComment
                    , handleOnClick SetActiveComment
                    ]
                    [ text commentText ]
                :: viewCommentedText commentedText restComments newLastProcessedIndex

        [] ->
            [ span [] [ text <| String.slice lastProcessedIndex (String.length commentedText) commentedText ] ]


viewCommentSection : List ProofreadComment -> Maybe Int -> Html msg
viewCommentSection comments activeCommentId =
    let
        activeComment =
            getComment comments activeCommentId
    in
    case activeComment of
        Just comment ->
            div [ class "comment-section" ]
                [ div [ class "l-text" ] [ text comment.hint.name ]
                , div [ class "comment-text"] [ text comment.hint.description ]
                ]

        Nothing ->
            viewEmptySection

viewSummarySection : Language -> ProofreadResult -> Html msg
viewSummarySection language result =
    table [ class "summary-table summary-table__full-width" ] [
        tr []
            [ td [ class "summary-cell" ]
                    [ table [ class "summary-table" ]
                        [
                            tr []
                                [ td [] [ div [ class "xl-text" ] [ text result.score ] ]
                                , td []
                                    [ div []
                                        [ text <| translate language ScoreText
                                        , div [] []
                                        , text <| translate language ByGlvrdScaleText ]
                                    ]
                                ]
                        ]
                    ]
            , td []
                [
                    table [ class "summary-table" ]
                        [
                            tr []
                                [ td [] [ div [ class "xl-text" ] [ text <| toString <| List.length result.fragments ] ]
                                , td [] [ text <| translate language (StopWordsText { number = List.length result.fragments }) ]
                                ]
                        ]
                    ]
                ]
            ]

-- UTILITY


handleOnMouseLeave : msg -> Attribute msg
handleOnMouseLeave msg =
    onMouseLeave msg


handleOnMouseEnter : (String -> msg) -> Attribute msg
handleOnMouseEnter tagger =
    on "mouseenter" (Json.Decode.map tagger targetDataId)


handleOnClick : (String -> msg) -> Attribute msg
handleOnClick tagger =
    on "click" (Json.Decode.map tagger targetDataId)


targetDataId : Decoder String
targetDataId =
    at [ "target", "id" ] string


getComment : List ProofreadComment -> Maybe Int -> Maybe ProofreadComment
getComment comments commentId =
    case commentId of
        Just id ->
            List.head <| List.filter (\comment -> comment.start == id) comments

        Nothing ->
            Nothing
