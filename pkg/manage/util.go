package manage

import (
	"net/http"
	"time"

	"github.com/gochan-org/gochan/pkg/gclog"
	"github.com/gochan-org/gochan/pkg/gcsql"
	"github.com/gochan-org/gochan/pkg/serverutil"
	"golang.org/x/crypto/bcrypt"
)

const (
	_ = iota
	sSuccess
	sInvalidPassword
	sOtherError
)

func createSession(key string, username string, password string, request *http.Request, writer http.ResponseWriter) int {
	//returns 0 for successful, 1 for password mismatch, and 2 for other
	domain := request.Host
	var err error
	domain = chopPortNumRegex.Split(domain, -1)[0]

	if !serverutil.ValidReferer(request) {
		gclog.Print(gclog.LStaffLog, "Rejected login from possible spambot @ "+request.RemoteAddr)
		return 2
	}
	staff, err := gcsql.GetStaffByName(username)
	if err != nil {
		gclog.Print(gclog.LErrorLog, err.Error())
		return 1
	}

	success := bcrypt.CompareHashAndPassword([]byte(staff.PasswordChecksum), []byte(password))
	if success == bcrypt.ErrMismatchedHashAndPassword {
		// password mismatch
		gclog.Print(gclog.LStaffLog, "Failed login (password mismatch) from "+request.RemoteAddr+" at "+time.Now().Format(gcsql.MySQLDatetimeFormat))
		return 1
	}

	// successful login, add cookie that expires in one month
	http.SetCookie(writer, &http.Cookie{
		Name:   "sessiondata",
		Value:  key,
		Path:   "/",
		Domain: domain,
		MaxAge: 60 * 60 * 24 * 7,
	})

	if err = gcsql.CreateSession(key, username); err != nil {
		gclog.Print(gclog.LErrorLog, "Error creating new staff session: ", err.Error())
		return 2
	}

	return 0
}

func getCurrentStaff(request *http.Request) (string, error) { //TODO after refactor, check if still used
	sessionCookie, err := request.Cookie("sessiondata")
	if err != nil {
		return "", err
	}
	name, err := gcsql.GetStaffName(sessionCookie.Value)
	if err == nil {
		return "", err
	}
	return name, nil
}

func getCurrentFullStaff(request *http.Request) (*gcsql.Staff, error) {
	sessionCookie, err := request.Cookie("sessiondata")
	if err != nil {
		return nil, err
	}
	return gcsql.GetStaffBySession(sessionCookie.Value)
}

// GetStaffRank returns the rank number of the staff referenced in the request
func GetStaffRank(request *http.Request) int {
	staff, err := getCurrentFullStaff(request)
	if err != nil {
		gclog.Print(gclog.LErrorLog, "Error getting current staff: ", err.Error())
		return 0
	}
	return staff.Rank
}