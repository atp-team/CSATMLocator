0.10.0
- OneTimePassword functionality now works as expected
- Normalized public API protocol names to CoreSDKAPI and LockerAPI
- Fixed bug where new lock type was not saved after password change
- Fixed bug where LockerStatusChanged notification did not fire sometimes
- Fixed bug where notifications would fire multiple times for the same locker status
- Fixed bug where AccessToken was accessible after lock
- Fixed bug where AccessTokenExpiration was sometimes nil
- Fixed a bug where access token expiration was sometimes not perserved in keychain.
- Fixed bug where LockType in Locker.Status was not reset when the user unregisters
- Fixed bug where ClientId in Locker.Status was set on AppClientID sometimes.
- Fixed bug where User would not get unregistered when received 401 during unlock
- (Internal) refactored test cases for better extensibility and readability
- (Internal) added more test cases

0.9.0
- Initial release