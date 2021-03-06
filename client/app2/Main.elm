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
import Maybe

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
    { oidcConfig : Model
    }

type alias IdToken =
  { iss : String
  , name : String
  , preferred_username : String
  , org : Maybe String
  , idTokenRaw : String
  }

type alias Model =
    { idToken : Maybe IdToken
    , oidcBaseUrl: String
    , redirectUri: String
    }

type Msg
    = RedirectFormPost
      | PopupOktaPostMessage
      | RedirectCodeFlow
      | RedirectFragement
      | Logout

--------------------------------------------------
-- INIT
--------------------------------------------------

init : ProgramOptions  -> (Model, Cmd Msg)
init opt = ( opt.oidcConfig, Cmd.none )


--------------------------------------------------
-- UPDATE
--------------------------------------------------

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    PopupOktaPostMessage -> ( model, invokeAuthFn "popupOktaPostMessage" )
    RedirectFormPost -> ( model, invokeAuthFn "redirectFormPost" )
    RedirectCodeFlow -> ( model, invokeAuthFn "redirectCodeFlow" )
    RedirectFragement -> ( model, invokeAuthFn "redirectFragment" )
    Logout -> ( model, invokeAuthFn "logout" )


--------------------------------------------------
-- VIEW
--------------------------------------------------

view : Model -> Html Msg
view m =
    div [ name "elm-main-container" ]
      [ viewButtons
      , viewToken m
      ]

viewButtons : Html Msg
viewButtons =
    div [ class "ui list"]
        [ div [ class "item" ]
              [ div [ class "content"]
                    [ button [ id "login"
                             , class "ui icon button blue"
                             , onClick RedirectFormPost
                             ]
                          [ text "Redirect - response_mode=form_post and access token, id token " ]
                    ]
              ]

        , div [ class "item" ]
            [ div [ class "content"]
                  [ button [ class "ui icon button blue"
                           , onClick RedirectFragement
                           ]
                        [ text "Redirect - response_mode=null and access token, id token" ]
                  ]
            ]

        , div [ class "item" ]
            [ div [ class "content"]
                  [ button [ id "login-code-flow"
                           , class "ui icon button blue"
                           , onClick RedirectCodeFlow
                           ]
                        [ text "Redirect - response_mode=null and auth code" ]
                  ]
            ]

        , div [ class "item" ]
            [ div [ class "content"]
                  [ button [ id "login-okta-post-message"
                           , class "ui icon button blue"
                           , onClick PopupOktaPostMessage
                           ]
                        [ text "Popup - response_mode=form_post" ]
                  ]
            ]

        ]

viewToken : Model -> Html Msg
viewToken m =
    case m.idToken of
        Nothing -> span [] [ text "no id token found" ]
        Just t -> div []
                  [ h1 [] [ text "id_token" ]
                  , ul []
                    (List.append
                      [ li [] [ code [] [ text t.idTokenRaw ] ]
                      , li [] [ text ("issuer: " ++ t.iss) ]
                      , li [] [ text ("name: " ++ t.name) ]
                      , li [] [ text ("preferred_username: " ++ t.preferred_username) ]
                      ]
                      (orgInfo t.org)
                    )
                  , div []
                      [ logoutButton ]
                  ]

orgInfo : Maybe String -> List (Html Msg)
orgInfo org =
  case org of
    Nothing -> []
    Just o -> [li [] [ text ("org: " ++ o) ]]

logoutButton : Html Msg
logoutButton =
  button 
    [ class "ui button blue"
    , onClick Logout
    ]
    [ text "/v1/logout"]

--------------------------------------------------
-- PORTs
--------------------------------------------------

port invokeAuthFn : String -> Cmd msg
