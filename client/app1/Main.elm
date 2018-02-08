{-
/*!
* Copyright (c) 2015-2016, Okta, Inc. and/or its affiliates. All rights reserved.
* The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
*
* You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
* WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*
* See the License for the specific language governing permissions and limitations under the License.
*/
-}

port module Main exposing (..)

import Dict exposing (..)
import Html exposing (..)
import Html as Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import String
import Navigation
import Date
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline as DP

main : Program ProgramOptions Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }


--------------------------------------------------
-- MODEL
--------------------------------------------------

type alias ProgramOptions =
    { accessTokenResp : Maybe AccessTokenResp
    , userInfo : Maybe UserInfo
    }

type alias Model =
    { accessTokenResp : Maybe AccessTokenResp
    , userInfo : Maybe UserInfo
    , usage : List Usage
    }

type alias Usage =
    { solar : Int
    , pge : Int
    , net : Int
    , perc : Float
    }

type alias AccessTokenResp =
    { accessToken : String
    , scopes : List String
    }

type alias UserInfo =
    { sub : String
    , name : String
    }

type Msg
    = LoginRedirect

--------------------------------------------------
-- INIT
--------------------------------------------------

init : ProgramOptions  -> (Model, Cmd Msg)
init opt = let us = case opt.userInfo of
               Just ui -> usage2
               Nothing -> usage1
           in
               ( Model opt.accessTokenResp opt.userInfo us, Cmd.none )

usage1 : List Usage
usage1 =
    [ makeUsage 0 428 0.201
    , makeUsage 0 432 0.205
    , makeUsage 0 544 0.211
    , makeUsage 0 368 0.200
    ]

usage2 : List Usage
usage2 = [ makeUsage 105 428 0.201
         , makeUsage 122 432 0.205
         , makeUsage 145 544 0.211
         , makeUsage 116 368 0.200
         ]

makeUsage : Int -> Int -> Float -> Usage
makeUsage s p perc = Usage s p (p - s) perc

--------------------------------------------------
-- UPDATE
--------------------------------------------------

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    LoginRedirect -> ( model, loginRedirect () )


--------------------------------------------------
-- VIEW
--------------------------------------------------

view : Model -> Html Msg
view m =
    div []
        [ div [ class "ui container"]
              [ div [ class "ui grid"]
                    [ div [class "two wide column"] [ img [ class "ui image", src "/assets/images/pge-spot-full-rgb-pos-lg.png"] [] ]
                    , div [class "four wide column"] [ h2 [ class "ui huge header company-title"] [ text "Pacific Gas and Electric Company" ] ]
                    , div [class "ten wide column"] [ span [ class "pull-right"] [ text "Mark Stevens"] ]
                    ]
              ]

        , div [ class "ui container"]
            [ h1 [] [ text "Energy Production & Usage" ]
            , h5 [] [ text "123 Kent Ave, Kentfield, CA" ]
            , table [ class "ui celled striped table" ]
                [ thead []
                      [ tr []
                            (List.map (\t -> th [] [ text t] ) [ "", "Jul", "Aug", "Sep", "Oct"])
                      ]
                , tbody []
                    [ solarRow m
                    , tr [] (td [] [text "Usage PG & E"] :: (List.map (\u -> td [] [text <| toString u.pge]) m.usage))
                    , tr [] (td [] [text "net"] :: (List.map (\u -> td [] [text <| toString u.net]) m.usage))
                    , tr [] (td [] [text "$/KwH"] :: (List.map (\u -> td [] [text <| toString u.perc]) m.usage))
                    ]
                ]
            ]

        , additionalData m
        ]

solarRow : Model -> Html Msg
solarRow m =
    case m.userInfo of
        Nothing -> tr []
                   [ td [] [ text "Solar Production"]
                   , td [colspan 4, class "link-solar-row"]
                       [ button
                             [ id "login"
                             , class "ui icon button blue"
                             , onClick LoginRedirect
                             ]
                             [ text "Link Solar Account" ]
                       ]
                   ]
        Just _ -> tr []
                  (td [] [ text "Solar Production (Vivint)"] :: (List.map (\u -> td [] [text <| toString u.solar]) m.usage))

additionalData : Model -> Html Msg
additionalData m =
    div [ class "ui container" ]
        [ h5 [ class "ui header" ] [ text "Additional Data" ],
          (case m.userInfo of
               Just ui -> displayUserInfo ui m.accessTokenResp
               Nothing -> p [] [ ]
          )
        ]

displayUserInfo : UserInfo -> Maybe AccessTokenResp -> Html Msg
displayUserInfo ui aresp =
    div [ class "ui grid" ]
        [ div [ class "four wide column" ]
              [ img [ class "ui image", src "/assets/images/vivint-solar.png" ] [] ]

        , div [ class "twelve wide column" ]
            [ h5 [ class "ui header" ] [ text ("Account Name: " ++ ui.name) ]
            , p [] [ text "This application can do following with Vivint Solar on your behalf: " ]
            , displayScopes aresp
            ]
        ]

displayScopes : Maybe AccessTokenResp -> Html Msg
displayScopes aresp =
    let scopes = case aresp of
                     Just ar -> List.filter (\s -> s /= "openid" && s /= "profile") ar.scopes
                     Nothing -> []
    in
        ul [] (List.map (\s -> li [] [ text s ]) scopes)

--------------------------------------------------
-- PORTs
--------------------------------------------------

port loginRedirect : () -> Cmd msg
