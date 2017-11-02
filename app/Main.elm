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
    { tokenResp : Maybe TokenResp
    , config : Config
    }

type alias Model =
    { config : Config
    , tokenResp : Maybe TokenResp
    , userInfo : Result String UserInfo
    , usage : List Usage
    }

type alias Config =
    { userInfoUrl : String
    }

type alias Usage =
    { solar : Int
    , pge : Int
    , net : Int
    , perc : Float
    }

type alias TokenResp =
    { idToken : String
    , accessToken : String
    , scope : List String
    }

type alias UserInfo =
    { email : String
    , scope : List String
    }

type Msg
    = LoginRedirect
    | Logout
    | UserInfoResp (Result Http.Error UserInfo)

--------------------------------------------------
-- INIT
--------------------------------------------------

init : ProgramOptions  -> (Model, Cmd Msg)
init opt =
  case opt.tokenResp of
      Nothing -> ( Model opt.config Nothing (Err "") defaultUsage, Cmd.none )
      Just tr -> ( Model opt.config (Just tr) (Err "") defaultUsage, fetchUserInfo opt.config tr )

defaultUsage : List Usage
defaultUsage =
    [ makeUsage 0 428 0.201
    , makeUsage 0 432 0.205
    , makeUsage 0 544 0.211
    , makeUsage 0 368 0.200
    ]

makeUsage : Int -> Int -> Float -> Usage
makeUsage s p perc = Usage s p (p - s) perc

--------------------------------------------------
-- UPDATE
--------------------------------------------------

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    LoginRedirect ->
        ( model, loginRedirect () )

    -- auth sdk will take care of logout hence keep model unchanged so far
    -- otherwise double refresh (model change refresh plus after logout refresh)
    Logout -> ( model, logout () )

    UserInfoResp (Ok user) -> let scope2 = case model.tokenResp of
                                          Nothing -> []
                                          Just tr -> tr.scope
                                  user2 = Ok { user | scope = scope2 }
                                  usage2 = [ makeUsage 105 428 0.201
                                           , makeUsage 122 432 0.205
                                           , makeUsage 145 544 0.211
                                           , makeUsage 116 368 0.200
                                           ]
                              in ( { model | userInfo = user2, usage = usage2 }, Cmd.none )
    UserInfoResp (Err e) -> ( { model | userInfo = Err (toString e) }, Cmd.none)


fetchUserInfo : Config -> TokenResp -> Cmd Msg
fetchUserInfo config tr =
    let req = Http.request
              { method = "GET"
              , headers =
                    [ Http.header "Authorization" ("Bearer " ++ tr.accessToken)
                    ]
              , url = config.userInfoUrl
              , body = Http.emptyBody
              , expect = Http.expectJson decodeUserInfo
              , timeout = Nothing
              , withCredentials = False
              }
    in
        Http.send UserInfoResp req

decodeUserInfo : Decode.Decoder UserInfo
decodeUserInfo =
    DP.decode UserInfo
        |> DP.required "email" Decode.string
        |> DP.hardcoded []


--------------------------------------------------
-- VIEW
--------------------------------------------------

view : Model -> Html Msg
view m =
    div []
        [ section []
              [ img [ class "company-logo", src "/assets/images/pge-spot-full-rgb-pos-lg.png"] []
              , h2 [ class "company-title"] [ text "Pacific Gas and Electric Company" ]
              , span [] [ text "Mark Stevens"]
              ]

        , h1 [] [ text "Energy Production & Usage" ]
        , h5 [] [ text "123 Kent Ave, Kentfield, CA" ]
        , table [ class "ui collapsing celled table compact inverted grey" ]
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

        , displayUserInfo m
        ]

solarRow : Model -> Html Msg
solarRow m = case m.userInfo of
                 Err _ -> tr []
                          [ td [] [ text "Solar Production"]
                          , td [colspan 4]
                              [ button
                                    [ id "login"
                                    , datase "login-link"
                                    , class "ui icon button blue"
                                    , onClick LoginRedirect
                                    ]
                                    [ text "Link Solar Account" ]
                              ]
                          ]
                 Ok _ -> tr []
                         (td [] [ text "Solar Production (Vivint)"] :: (List.map (\u -> td [] [text <| toString u.solar]) m.usage))

displayUserInfo : Model -> Html Msg
displayUserInfo m =
    div []
        [ h5 [] [ text "Additional Data" ],
              (case m.userInfo of
                   Ok ui -> div []
                            [ div [] [ text "icon"]
                            , div []
                                [ p [] [ text ("Account Name " ++ ui.email) ]
                                , p [] [ text "This application can do following with Vivint Solar on your behalf: " ]
                                , ul [] (List.map (\s -> li [] [ text s ]) ui.scope)
                                ]

                            ]
                   Err e -> p [] [ text e ]
              )
        ]

fromInt : Int -> Date.Date
fromInt = Date.fromTime << toFloat << (*) 1000

datase : String -> Attribute msg
datase = attribute "data-se"

--------------------------------------------------
-- PORTs
--------------------------------------------------

port loginRedirect : () -> Cmd msg
port loginCustom : () -> Cmd msg
port logout : () -> Cmd msg
