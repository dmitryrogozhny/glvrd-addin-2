module Translation exposing (Translation, createNumeralTranslation, createNumeralsTranslation, createPluralTranslation, createTranslation, translate, translatePlural)


type Translation
    = SingleTranslation String
    | PluralTranslation String String (List NumeralTranslation)


type NumeralTranslation
    = NumeralTranslation Int String


createTranslation : String -> Translation
createTranslation translation =
    SingleTranslation translation


createPluralTranslation : String -> String -> Translation
createPluralTranslation single plural =
    createNumeralsTranslation single plural []


createNumeralsTranslation : String -> String -> List NumeralTranslation -> Translation
createNumeralsTranslation single plural numeralTranslations =
    PluralTranslation single plural numeralTranslations


createNumeralTranslation : Int -> String -> NumeralTranslation
createNumeralTranslation number text =
    NumeralTranslation number text


translate : Translation -> String
translate translation =
    case translation of
        SingleTranslation single ->
            single

        PluralTranslation single plural numeralTranslations ->
            single


translatePlural : Translation -> Int -> String
translatePlural translation value =
    case translation of
        SingleTranslation single ->
            single

        PluralTranslation single plural numeralTranslations ->
            if value == 1 then
                single
            else
                let
                    numeralTranslation =
                        List.filter (\(NumeralTranslation number _) -> number == value) numeralTranslations
                            |> List.head
                in
                case numeralTranslation of
                    Nothing ->
                        plural

                    Just (NumeralTranslation _ text) ->
                        text
