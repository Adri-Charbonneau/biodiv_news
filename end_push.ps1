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