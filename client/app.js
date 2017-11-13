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

import OktaAuth from '@okta/okta-auth-js/jquery';
import loginRedirect from './login-redirect';
import Elm from './Main.elm';

require('./main.css');

export function bootstrap (config) {
  const authzUrl = `${config.oktaUrl}oauth2/${config.asId}/v1/authorize`;
  const issuer = `${config.oktaUrl}oauth2/${config.asId}`;

  // init auth sdk
  const auth = new OktaAuth({
    url: config.oktaUrl,
    issuer: issuer,
    clientId: config.clientId,
    redirectUri: config.redirectUri,
    authorizeUrl: authzUrl,
  });

  const renderView = (accessTokenObj, userInfo) => {
    // render main view
    const containerEl = document.querySelector(config.container);
    const app = Elm.Main.embed(containerEl, {
      accessTokenResp: accessTokenObj,
      userInfo: userInfo,
    });
    // Elm -> JS
    app.ports.loginRedirect.subscribe(() => {
      loginRedirect(auth);
    });
  };

  auth.token.parseFromUrl()
    .then(function (tokens) {
      const accessTokenObj = tokens[0];

      return auth.token.getUserInfo(accessTokenObj)
        .then(function (user) {
          renderView(accessTokenObj, user);
        });
    })
    .catch(function (err) {
      console.warn(err);
      renderView(null, null);
    });
}

export default bootstrap;
