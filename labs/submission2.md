## Before changing, original version of .yaml file

| Severity     | Category                  | Asset         | Likelihood   | Impact | Score |
|--------------|---------------------------|--------------|--------------|--------|-------|
| Elevated (4) | Unencrypted Communication | User Browser | Likely (3)   | High (3) | **433** |
| Elevated (4) | Unencrypted Communication | User Browser | Likely (3)   | High (3) | **433** |
| Elevated (4) | Unencrypted Communication | Reverse Proxy | Likely (3)  | Medium (2) | **432** |
| Elevated (4) | Missing Authentication    | Juice Shop   | Likely (3)   | Medium (2) | **432** |
| Elevated (4) | Cross-Site Scripting (XSS)| Juice Shop   | Likely (3)   | Medium (2) | **432** |

***Stats for this state:***
```
{
	"risks": {
		"critical": {
			"accepted": 0,
			"false-positive": 0,
			"in-discussion": 0,
			"in-progress": 0,
			"mitigated": 0,
			"unchecked": 0
		},
		"elevated": {
			"accepted": 0,
			"false-positive": 0,
			"in-discussion": 0,
			"in-progress": 0,
			"mitigated": 0,
			"unchecked": 5
		},
		"high": {
			"accepted": 0,
			"false-positive": 0,
			"in-discussion": 0,
			"in-progress": 0,
			"mitigated": 0,
			"unchecked": 0
		},
		"low": {
			"accepted": 0,
			"false-positive": 0,
			"in-discussion": 0,
			"in-progress": 0,
			"mitigated": 0,
			"unchecked": 5
		},
		"medium": {
			"accepted": 0,
			"false-positive": 0,
			"in-discussion": 0,
			"in-progress": 0,
			"mitigated": 0,
			"unchecked": 13
		}
	}
}
```

## Threat Dragon vs Threagile

**Overlaps:**
1. Spamming [Elevation of privilege] - includes XSS data stealing
2. Scraping [Information Disclosure] - unencrypted HTTP data may be collected due to Unencrypted Communication

**Difference:**
1. Vulnerability Scanning [Information Disclosure] - Threagile did not find a threat of enumeration


## Delta Run after threat evidence

`communication_links To Reverse Proxy protocol set to HTTPS`

| Severity     | Category                 | Asset       | Likelihood   | Impact | Score |
|--------------|--------------------------|------------|--------------|--------|-------|
| Elevated (4) | Unencrypted Communication| User Browser | Likely (3)  | High (3) | **433** |
| Elevated (4) | Missing Authentication   | Juice Shop   | Likely (3)  | Medium (2) | **432** |
| Elevated (4) | Cross-Site Scripting (XSS)| Juice Shop  | Likely (3)  | Medium (2) | **432** |
| Elevated (4) | Unencrypted Communication| Reverse Proxy| Likely (3)  | Medium (2) | **432** |
| Medium (2)   | Cross-Site Request Forgery (CSRF) | Juice Shop | Very-Likely (4) | Low (1) | **241** |

***Stats for this state:***
```
{
	"risks": {
		"critical": {
			"accepted": 0,
			"false-positive": 0,
			"in-discussion": 0,
			"in-progress": 0,
			"mitigated": 0,
			"unchecked": 0
		},
		"elevated": {
			"accepted": 0,
			"false-positive": 0,
			"in-discussion": 0,
			"in-progress": 0,
			"mitigated": 0,
			"unchecked": 4
		},
		"high": {
			"accepted": 0,
			"false-positive": 0,
			"in-discussion": 0,
			"in-progress": 0,
			"mitigated": 0,
			"unchecked": 0
		},
		"low": {
			"accepted": 0,
			"false-positive": 0,
			"in-discussion": 0,
			"in-progress": 0,
			"mitigated": 0,
			"unchecked": 5
		},
		"medium": {
			"accepted": 0,
			"false-positive": 0,
			"in-discussion": 0,
			"in-progress": 0,
			"mitigated": 0,
			"unchecked": 13
		}
	}
}
```


> Now, one Unencrypted Communication is gone (taking away the elevated risk), as the protocol was changed from unsafe and unencrypted HTTP to HTTPS
---