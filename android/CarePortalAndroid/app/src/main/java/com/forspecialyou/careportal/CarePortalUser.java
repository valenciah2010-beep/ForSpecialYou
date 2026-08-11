package com.forspecialyou.careportal;

import org.json.JSONException;
import org.json.JSONObject;

final class CarePortalUser {
    final int id;
    final String nickname;
    final String email;
    final String role;
    final String profileImage;

    CarePortalUser(int id, String nickname, String email, String role, String profileImage) {
        this.id = id;
        this.nickname = nickname == null ? "" : nickname;
        this.email = email == null ? "" : email;
        this.role = role == null ? "" : role;
        this.profileImage = profileImage;
    }

    static CarePortalUser fromJson(JSONObject json) throws JSONException {
        return new CarePortalUser(
                json.optInt("id"),
                json.optString("nickname"),
                json.optString("email"),
                json.optString("role"),
                json.isNull("profileImage") ? null : json.optString("profileImage")
        );
    }

    JSONObject toJson() throws JSONException {
        JSONObject json = new JSONObject();
        json.put("id", id);
        json.put("nickname", nickname);
        json.put("email", email);
        json.put("role", role);
        if (profileImage == null) {
            json.put("profileImage", JSONObject.NULL);
        } else {
            json.put("profileImage", profileImage);
        }
        return json;
    }
}
