package com.jaykisan.jaykisan_card;

import android.accounts.Account;
import android.accounts.AccountManager;
import android.content.pm.PackageManager;
import android.os.Bundle;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class MainActivity extends FlutterFragmentActivity {
    private static final String CHANNEL = "com.jaykisan.jaykisan_card/device_accounts";
    private static final int PERMISSION_REQUEST_GET_ACCOUNTS = 1001;
    private MethodChannel.Result pendingResult;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler((call, result) -> {
                switch (call.method) {
                    case "getDeviceAccounts":
                        getDeviceAccounts(result);
                        break;
                    case "requestAccountsPermission":
                        requestAccountsPermission(result);
                        break;
                    default:
                        result.notImplemented();
                        break;
                }
            });
    }

    private void getDeviceAccounts(MethodChannel.Result result) {
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.GET_ACCOUNTS)
                != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "GET_ACCOUNTS permission not granted", null);
            return;
        }

        try {
            AccountManager accountManager = AccountManager.get(this);
            Account[] accounts = accountManager.getAccounts();
            
            Set<String> emailSet = new HashSet<>();
            List<String> googleAccounts = new ArrayList<>();
            List<String> otherAccounts = new ArrayList<>();
            
            for (Account account : accounts) {
                String accountName = account.name;
                String accountType = account.type;
                
                // Check if it's an email address
                if (accountName != null && accountName.contains("@")) {
                    emailSet.add(accountName);
                    
                    // Separate Google accounts from others
                    if ("com.google".equals(accountType) || accountName.toLowerCase().contains("@gmail.com")) {
                        googleAccounts.add(accountName);
                    } else {
                        otherAccounts.add(accountName);
                    }
                }
            }
            
            // Combine lists with Google accounts first
            List<String> allAccounts = new ArrayList<>();
            allAccounts.addAll(googleAccounts);
            allAccounts.addAll(otherAccounts);
            
            result.success(allAccounts);
        } catch (Exception e) {
            result.error("ERROR", "Failed to get device accounts: " + e.getMessage(), null);
        }
    }

    private void requestAccountsPermission(MethodChannel.Result result) {
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.GET_ACCOUNTS)
                == PackageManager.PERMISSION_GRANTED) {
            result.success(true);
            return;
        }

        pendingResult = result;
        ActivityCompat.requestPermissions(this,
                new String[]{android.Manifest.permission.GET_ACCOUNTS},
                PERMISSION_REQUEST_GET_ACCOUNTS);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions,
                                         @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        
        if (requestCode == PERMISSION_REQUEST_GET_ACCOUNTS && pendingResult != null) {
            boolean granted = grantResults.length > 0 && 
                            grantResults[0] == PackageManager.PERMISSION_GRANTED;
            pendingResult.success(granted);
            pendingResult = null;
        }
    }
}
