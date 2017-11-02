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
    }

type alias Config =
    { userInfoUrl : String
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
      Nothing -> ( Model opt.config Nothing (Err ""), Cmd.none )
      Just tr -> ( Model opt.config (Just tr) (Err ""), fetchUserInfo opt.config tr )


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

    UserInfoResp (Ok user) -> let u = case model.tokenResp of
                                          Nothing -> user
                                          Just tr -> { user | scope = tr.scope }
                              in ( { model | userInfo = Ok u}, Cmd.none )
    UserInfoResp (Err e) -> ( { model | userInfo = Err (toString e) }, Cmd.none)

-- Authorization: Bearer <access_token>

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
view = loginRedirectHtml

-- case List.head model.history of

loginRedirectHtml : Model -> Html Msg
loginRedirectHtml m =
    div []
        [ h1 [] [ text "Energy Production & Usage" ]
        , h5 [] [ text "123 Kent Ave, Kentfield, CA" ]

        , table [ class "ui collapsing celled table compact inverted grey" ]
                [ thead []
                        [ tr []
                             (List.map (\t -> th [] [ text t] ) [ "", "Jul", "Aug", "Sep", "Oct"])
                        ]
                , tbody []
                        [ tr []
                             [
                             ]
                        ]
                ]
        , p []
            [ button
                  [ id "login"
                  , datase "login-link"
                  , class "ui icon button blue"
                  , onClick LoginRedirect
                  ]
                  [ i [ class "sign in icon" ] []
                  , text "Login with Okta"
                  ]
            ]

        , displayUserInfo m

            --(case m.tokenResp of
              --  Nothing -> []
                --Just t -> [ text t.accessToken ])
        ]

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
