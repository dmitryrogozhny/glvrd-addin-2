module AppTranslation exposing (..)

import Translation


type Language
    = English
    | Russian


type ResourceId
    = PlaceholderText
    | OpenInGlvrdText
    | OpenInGlvrdUrl
    | AboutText
    | AboutUrl
    | StopWordsText { number : Int }
    | ScoreText
    | ByGlvrdScaleText
    | GlvrdNotAvailable


type alias TranslationSet =
    { english : String
    , russian : String
    }


translate : Language -> ResourceId -> String
translate language resourceId =
    let
        translationSet =
            case resourceId of
                PlaceholderText ->
                    TranslationSet "Please select text to start proofreading" "Выделите текст, чтобы начать проверку"

                OpenInGlvrdText ->
                    TranslationSet "Open in Glvrd" "Открыть в Главреде"

                OpenInGlvrdUrl ->
                    TranslationSet "https://glvrd.ru/" "https://glvrd.ru/"

                AboutText ->
                    TranslationSet "About" "О программе"

                AboutUrl ->
                    TranslationSet "./pages/about_en.html" "./pages/about_ru.html"

                StopWordsText { number } ->
                    let
                        english =
                            Translation.createPluralTranslation "stop word" "stop words"

                        russian =
                            Translation.createNumeralsTranslation "стоп-слово"
                                "стоп-слов"
                                [ Translation.createNumeralTranslation 2 "стоп-слова"
                                , Translation.createNumeralTranslation 3 "стоп-слова"
                                , Translation.createNumeralTranslation 4 "стоп-слова"
                                ]
                    in
                    TranslationSet (Translation.translatePlural english number) (Translation.translatePlural russian number)

                ScoreText ->
                    TranslationSet "Glvrd points" "из 10"

                ByGlvrdScaleText ->
                    TranslationSet "out of 10" "по шкале Главреда"

                GlvrdNotAvailable ->
                    TranslationSet "Glvrd service is not available. Please, try again later." "Сервис Главреда недоступен. Попробуйте повторить проверку через 5 минут."
    in
    case language of
        English ->
            .english translationSet

        Russian ->
            .russian translationSet
