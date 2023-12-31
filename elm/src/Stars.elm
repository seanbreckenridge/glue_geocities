port module Stars exposing (main)

-- This generates/animates random stars for the home page, in the viewable area, and handles re-drawing when the screen scrolls

import Array exposing (Array, fromList, get, length)
import Browser exposing (element)
import Browser.Events exposing (Visibility(..))
import Html exposing (Html, div, img)
import Html.Attributes exposing (alt, class, id, src, style)
import Html.Lazy exposing (lazy2)
import List exposing (map)
import Maybe exposing (Maybe, withDefault)
import Time


port scrollOrResize : (ScreenData -> msg) -> Sub msg


{-| URLs for the star URLs generated in javascript
-}
type alias Flag =
    { starUrls : List String, randomNumbers : List Float, defaultRandom : Float }


{-| X, Y position on the page
-}
type alias Coordinate =
    { x : Int
    , y : Int
    }


{-| Data to generate one star on the page
-}
type alias Star =
    { loc : Coordinate -- location on the screen
    , starIndex : Int
    , fadeType : Int -- number from 1-5 that specifies the CSS animation keyframe for this star
    }


type alias Model =
    { active : Visibility
    , screenData : Maybe ScreenData
    , starUrls : Array String
    , stars : List Star
    , randomNumbers : Array Float
    , defaultRandom : Float
    , rngIndex : Int
    }


type alias ScreenData =
    { scrollY : Int
    , viewportHeight : Int
    , viewportWidth : Int
    }


init : Flag -> ( Model, Cmd Msg )
init flags =
    ( { active = Visible
      , screenData = Nothing
      , starUrls = fromList flags.starUrls
      , stars = []
      , randomNumbers = fromList flags.randomNumbers
      , defaultRandom = flags.defaultRandom
      , rngIndex = 0
      }
    , Cmd.none
    )


isPaused vis =
    case vis of
        Visible ->
            False

        Hidden ->
            True


type Msg
    = VisibilityChanged Visibility
    | OnScroll ScreenData
    | ChangeStars Time.Posix


generateNewStarLocations : Model -> ScreenData -> Model
generateNewStarLocations model screenData =
    let
        starCount =
            100

        -- number of random elements to use for each star
        indexOffset =
            4

        -- update the index into the random number array modulo random array length
        newRngIndex =
            remainderBy (length model.randomNumbers) (model.rngIndex + (starCount * indexOffset))
    in
    { model
        | rngIndex = newRngIndex
        , stars = generateRandomStar model.randomNumbers screenData [] model.defaultRandom starCount 0 model.rngIndex indexOffset
    }


{-| non inclusive
-}
randInt : Float -> Int -> Int -> Int
randInt fromRandValue from till =
    remainderBy (till - from) (floor (toFloat till * fromRandValue * 100.0)) + from


indexIntoRng : Array Float -> Int -> Float -> Float
indexIntoRng randomNumbers index defaultVal =
    let
        safeIndex =
            remainderBy (length randomNumbers) index
    in
    get safeIndex randomNumbers |> withDefault defaultVal


{-| Recursively generate stars
-}
generateRandomStar : Array Float -> ScreenData -> List Star -> Float -> Int -> Int -> Int -> Int -> List Star
generateRandomStar randomNumbers screenData starArr defaultRngVal tillStarCount curCount index indexOffset =
    -- while there are still more stars to generate (tillStarCount)
    if curCount < tillStarCount then
        let
            -- create new star, use offsets into the randomly generated array
            -- to simulate a PRNG
            newStarArr =
                starArr
                    ++ [ { fadeType = randInt (indexIntoRng randomNumbers index defaultRngVal) 1 6
                         , starIndex = randInt (indexIntoRng randomNumbers (index + 1) defaultRngVal) 0 9 -- 9 items in the array
                         , loc =
                            -- use 25 as buffer on the right so that star isn't just in the corner off the page
                            { x = randInt (indexIntoRng randomNumbers (index + 2) defaultRngVal) 2 (screenData.viewportWidth - 25)
                            , y = randInt (indexIntoRng randomNumbers (index + 3) defaultRngVal) (screenData.scrollY + 2) (screenData.viewportHeight + screenData.scrollY - 25)
                            }
                         }
                       ]
        in
        generateRandomStar randomNumbers
            screenData
            newStarArr
            defaultRngVal
            tillStarCount
            (curCount + 1)
            (index + indexOffset)
            indexOffset

    else
        starArr


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- if user switches tabs/browser visibiity changes
        VisibilityChanged vis ->
            ( { model | active = vis }
            , Cmd.none
            )

        -- if the user scrolls/resizes the browser
        OnScroll data ->
            -- run generateNewStarLocations whenever the user scrolls the page
            let
                newModel =
                    -- if isEmpty model.stars then
                    generateNewStarLocations model data

                -- else
                -- model
            in
            ( { newModel | screenData = Just data }, Cmd.none )

        ChangeStars _ ->
            if isPaused model.active then
                ( model, Cmd.none )

            else
                case model.screenData of
                    Just data ->
                        ( generateNewStarLocations model data, Cmd.none )

                    Nothing ->
                        ( model, Cmd.none )


toPixel : Int -> String
toPixel n =
    String.fromInt n ++ "px"


{-| Render a random star at a random X,Y location and star animation type
-}
renderStar : Star -> Array String -> Html Msg
renderStar star starUrls =
    img
        [ class ("img-star star-anim-" ++ String.fromInt star.fadeType)
        , style
            "left"
            (toPixel star.loc.x)
        , style
            "top"
            (toPixel star.loc.y)
        , alt ""
        , src (get star.starIndex starUrls |> withDefault "didn't work")
        ]
        []


{-| render each of the stars
-}
view : Model -> Html Msg
view model =
    div
        []
        (map
            (\s -> lazy2 renderStar s model.starUrls)
            model.stars
        )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch <|
        [ Browser.Events.onVisibilityChange VisibilityChanged
        , scrollOrResize OnScroll
        , Time.every 10000 ChangeStars
        ]


main : Program Flag Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
