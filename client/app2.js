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

import OktaAuth from '@okta/okta-auth-js/';
import * as R from 'ramda';
import Elm from './app2/Main.elm';
import './app2/main.css';

export function bootstrap (config) {
  const issuer = `${config.oktaUrl}/oauth2/${config.asId}`;

  // init auth sdk
  const auth = new OktaAuth({
    url: config.oktaUrl,
    clientId: config.clientId,
    redirectUri: config.redirectUri,
    issuer,
    pkce: false,
    // tokenManager: {
    // autoRefresh: true
    // },
  });

  function redirectFormPost (auth) {
    auth.token.getWithRedirect({
      responseType: [
        'token',
        'id_token',
      ],
      scopes: [
        'openid',
        'profile',
      ],
      responseMode: 'form_post',
      prompt: 'consent',
      // prompt: 'login',
    });
  }

  function redirectFragment (auth) {
    auth.token.getWithRedirect({
      responseType: [
        'token',
        'id_token',
      ],
      scopes: [
        'openid',
        'profile',
      ],
      // prompt: 'consent',
      // prompt: 'login'
    });
  }

  function redirectCodeFlow (auth) {
    auth.token.getWithRedirect({
      responseType: [
        'code',
      ],
      scopes: [
        'openid',
        'profile',
      ],
      // prompt: 'consent',
    });
  }

  function popupOktaPostMessage (auth) {
    auth.token.getWithPopup({
      // responseType: ['token', 'id_token', ],
      responseType: ['id_token'],
      scopes: ['openid', 'profile', 'email',],
      // responseMode: 'okta_post_message', default response mode when `getWithPopup`
      // responseMode: 'fragment',
    })
      .then(resp => {
        const idTokenResp = resp.tokens && resp.tokens.idToken;
        if (idTokenResp) {
          auth.tokenManager.add('idToken', idTokenResp);
          auth.tokenManager.add('accessToken', resp.tokens.accessToken);
          renderView(idTokenResp.idToken);
        }
      });
  }

  async function logout () {
    await auth.revokeAccessToken(); // strongly recommended
    auth.closeSession()
      .then(() => {
        window.location.assign('/apps/app2');
      })
      .catch((err) => {
        console.error('app2.js - failed to logout', err);
      });
  }

  const authFns = {
    redirectCodeFlow,
    redirectFragment,
    popupOktaPostMessage,
    redirectFormPost,
    logout,
  };

  const renderView = (idTokenRaw = null) => {
    // render main view
    const containerEl = document.querySelector(config.container);

    let idToken = null;
    if (idTokenRaw) {
      const decodedIdToken = auth.token.decode(idTokenRaw).payload;
      const displayLabelOfIdToken = R.pick(['iss', 'name', 'org', 'preferred_username']);
      idToken = R.merge({
        idTokenRaw,
        org: null,
      }, displayLabelOfIdToken(decodedIdToken));
    }

    const app = Elm.Main.embed(containerEl, {
      oidcConfig: {
        oidcBaseUrl: config.oktaUrl,
        redirectUri: config.redirectUri,
        idToken,
      },
    });

    // Elm -> JS
    app.ports.invokeAuthFn.subscribe((fnName) => {
      const fn = authFns[fnName];
      if (!fn) {
        console.error(`cannot find auth handler for ${fnName}`);
      }
      fn(auth);
    });
  };

  if (config.idToken) {
    renderView(config.idToken);
  } else {
    auth.token.parseFromUrl()
      .then((resp = {}) => {
        const idTokenResp = resp.tokens && resp.tokens.idToken;
        if (!idTokenResp) {
          renderView();
        } else {
          auth.tokenManager.add('idToken', idTokenResp);
          auth.tokenManager.add('accessToken', resp.tokens.accessToken);
          renderView(idTokenResp.idToken);
        }
      })
      .catch((exception) => {
        console.error('error when read id token from uri', exception);
        renderView();
      });
  }

  window.aj = auth;
}

export default bootstrap;
