# GIT
git config --local user.email "github-actions[bot]@users.noreply.github.com"
git config --local user.name "github-actions[bot]"
git add .
git commit -m "[Bot] Mise à jour $name"
git push -f

# CORRECTION
$title = $title -replace '&#233;','é'
$title = $title -replace '&nbsp;',' '
$title = $title -replace '&rsquo;',"'"

## length of title for twitter
if ( $title.Length -ge 110 )
{ 
	$titletweet = $title.Substring(0, 110)
	$titletweet = -join($titletweet,"...")
	}else{
	$titletweet = $title
}

## replace character
$tmname = $name
$tmname = $tmname -replace '&','&amp;'

$tmtitle = $title
#$tmtitle = $tmtitle -replace '&nbsp;',' '
$tmtitle = $tmtitle -replace '&','%26'
#$tmtitle = $tmtitle -replace '<','&lt;'
#$tmtitle = $tmtitle -replace '>','&gt;'

$tmlink = $link
$tmlink = $tmlink -replace '&','%26'

## RESUME
echo "Valeurs de $name :"
echo "------------------"
echo "title = $link"
echo "tmtitle = $tmtitle"
echo "titletweet = $titletweet"
echo "------------------"
echo "link = $title"
echo "tmlink = $tmlink"
echo "------------------"

# TELEGRAM
$tmtext = "Nouvel article de $tmname : $tmtitle - $tmlink"
$tmtoken = "$env:TELEGRAM"
$tmchatid = "$env:CHAT_ID"
Invoke-RestMethod -Uri "https://api.telegram.org/bot$tmtoken/sendMessage?chat_id=$tmchatid&text=$tmtext"

# MASTODON
$mastodonheaders = @{Authorization = "Bearer $env:MASTODON"}
$mastodonform = @{status = "Nouvel article de $name ! $titletweet
	
Lien : $link
$tags"}
Invoke-WebRequest -Uri "https://piaille.fr/api/v1/statuses" -Headers $mastodonheaders -Method Post -Form $mastodonform

# TWITTER
$twitter = (Select-String -Path "config.txt" -Pattern "twitter=(.*)").Matches.Groups[1].Value
if ( $twitter -eq "y" ) {
	Install-Module PSTwitterAPI -Force
	Import-Module PSTwitterAPI
	$OAuthSettings = @{
		ApiKey = "$env:PST_KEY"
		ApiSecret = "$env:PST_KEY_SECRET"
		AccessToken = "$env:PST_TOKEN"
		AccessTokenSecret = "$env:PST_TOKEN_SECRET"
	}
	Set-TwitterOAuthSettings @OAuthSettings
	Send-TwitterStatuses_Update -status "Nouvel article de $name ! $titletweet
	
	Lien : $link
	$accounts
	$tags
	"
}

## BLUESKY
# suppression des accents en attendant une meilleure solution
function Remove-StringLatinCharacters
{
    PARAM ([string]$String)
    [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($String))
}

$bsky_title = Remove-StringLatinCharacters -String $titletweet

$session_url = "https://bsky.social/xrpc/com.atproto.server.createSession"

$session_body = @{
    "identifier" = "$env:BSKY_mail"
    "password" = "$env:BSKY_pass"
} | ConvertTo-Json

$session_headers = @{
    "Content-Type" = "application/json"
}

$session_response = Invoke-RestMethod -Uri $session_url -Method Post -Headers $session_headers -Body $session_body

## Post message
$post_url = "https://bsky.social/xrpc/com.atproto.repo.createRecord"
$token = $session_response.accessJwt
$did = $session_response.did
$text = "Nouvel article de $name ! $bsky_title
	
Lien : $link
"
$start = $text.IndexOf($link)
$end = $start + $link.Length

$post_body = @{
	"collection" = "app.bsky.feed.post"
	"repo" = $did
	"record" = @{
		"text" = "$text"
		"`$type" = "app.bsky.feed.post"
		"createdAt" = Get-Date (Get-Date).ToUniversalTime() -UFormat '+%Y-%m-%dT%H:%M:%S.000Z'
		"facets" = @( 
			@{
				"index" = @{
					"byteStart" = $start
					"byteEnd" = $end
				}
				"features" = @(
					@{
						"`$type" = "app.bsky.richtext.facet#link"
						"uri" = "$link"
					}
				)
			}
		)
	}
} | ConvertTo-Json -Depth 5

$post_headers = @{
	"Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Envoi de la requête POST
Invoke-RestMethod -Uri $post_url -Method Post -Headers $post_headers -Body $post_body