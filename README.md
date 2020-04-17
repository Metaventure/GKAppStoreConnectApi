# GKAppStoreConnectApi
Programmatically create promo codes for your App Store Connect apps.

Check out my blog post about it [here](https://blog.gikken.co/how-i-re-wrote-gikkens-app-store-connect-api-library/).

Log in to App Store Connect, fetch your teams and apps and request promo codes for them.

Our main use for this lib would be [Tokens 2](https://gikken.co/new-tokens)

Based on [ESSAppStoreConnectAPI](https://github.com/eternalstorms/ESSAppStoreConnectAPI), 
which is based on code taken from [fastlane](https://github.com/fastlane/fastlane), both under the MIT license.

This lib is a complete rewrite in pure Swift.

## Contributing
If you have any ideas on how the lib can be improved and you can implement them – submit a pull request, those are always welcome. 
You can also create issues, I will be looking at them from time to time.

## How to use

The lib is a singleton, so you don't have to initialize it, you just call the methods on `GKAppStoreConnectApi.shared`.

### The usage flow:

1. The first thing that needs to be done is you have to log in the user. There's `loginWith(username:password:)` for that. It will either immediately log the user in, or it will tell you that 2FA is active and your user needs to give you the code. You can also use the `info` object in the completion handler to see all the available 2FA options and give the user a choice. If you decide to do so – there's a `resend2FACodeWith(phoneID:)` method.

2. After you've got the code from te user – call `finish2FAWith(code:phoneID:)` it will automatically know if the code was sent to a trusted device or as an SMS and call the right endpoint, which are different for some reason. Now we have that sweet login cookie.
After we've got the cookie – the library will request the user session from the ASC, which contains all the info about the users teams, it also immediately downloads the apps for all the teams.

3. Access the apps via `getApps()`. If the app is paid and you need a promo code for it – use `requestPromoCodesForAppWith(appID:versionID:quantity:contractFilename:)`. You can find the versionID and the contractFilename parameters in the app object you got from `getApps()`. 
It takes some time to get the codes, so you're better off presenting an activity indicator while it loads.

4. Most probably, your app is free and it offers an IAP of some sort, cuz it's 2020, right? You will have to request a list of IAPs with `iapsForAppWith(appId:)`, and with that info you can use the `requestIapPromoCodesFor(iapID:appID: quantity:)`. Be patient, it's not instant too. Still much faster than the actual App Store Connect though 😏.
