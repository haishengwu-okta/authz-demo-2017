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
    { idToken : Maybe String
    }

type alias Model =
    { idToken : Maybe String
    }

type Msg
    = RedirectFormPost
      | PopupOktaPostMessage
      | RedirectCodeFlow

--------------------------------------------------
-- INIT
--------------------------------------------------

init : ProgramOptions  -> (Model, Cmd Msg)
init opt = ( Model opt.idToken, Cmd.none )


--------------------------------------------------
-- UPDATE
--------------------------------------------------

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    RedirectFormPost -> ( model, invokeAuthFn "redirectFormPost" )
    PopupOktaPostMessage -> ( model, invokeAuthFn "popupOktaPostMessage" )
    RedirectCodeFlow -> ( model, invokeAuthFn "redirectCodeFlow" )

--------------------------------------------------
-- VIEW
--------------------------------------------------

view : Model -> Html Msg
view m =
    div [ name "elm-main-container" ]
      [ viewButtons
      , viewToken m.idToken
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
                          [ text "Redirect - Okta Form Post" ]
                    ]
              ]
        , div [ class "item" ]
            [ div [ class "content"]
                  [ button [ id "login-okta-post-message"
                           , class "ui icon button blue"
                           , onClick PopupOktaPostMessage
                           ]
                        [ text "Popup - Okta Post Message" ]
                  ]
            ]

        , div [ class "item" ]
            [ div [ class "content"]
                  [ button [ id "login-code-flow"
                           , class "ui icon button blue"
                           , onClick RedirectCodeFlow
                           ]
                        [ text "Redirect - authorize code" ]
                  ]
            ]

        ]
viewToken : Maybe String -> Html Msg
viewToken token =
    case token of
        Nothing -> span [] [ text "no id token found" ]
        Just t -> div []
                  [ h1 [] [ text "id_token" ]
                  , code [] [ text t ]
                  ]

--------------------------------------------------
-- PORTs
--------------------------------------------------

port invokeAuthFn : String -> Cmd msg
port redirectFormPost : () -> Cmd msg
port popupOktaPostMessage : () -> Cmd msg
