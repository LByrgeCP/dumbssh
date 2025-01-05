package logger

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"

	. "github.com/logrusorgru/aurora"
	. "github.com/mattn/go-colorable"

	. "github.com/LByrgeCP/coordinate-kali/internal/globals"
)

var (
	logger *log.Logger
	tabs   string
)

func InitLogger() {
	logger = log.New(NewColorableStdout(), "", 0)
}

func Tabber(tabnum int) {
	tabs = ""
	for i := 0; i < tabnum; i++ {
		tabs += "\t"
	}
}

func Time() string {
	return time.Now().Format("03:04:05PM")
}

func Stdout(i Instance, a ...interface{}) {
	var f *os.File
	logger.Printf("%s%s%s%s%s", Green(""), Brown(""), Red(""), BrightCyan(""), BrightCyan(""))
	logger.Printf("%s%s:%s%s\n%s", tabs, BrightCyan("[STDOUT"), Summary(i), BrightCyan("]"), White(fmt.Sprintln(a...)))
	if !(len(*Outfile) == 0) {
		filePath := filepath.Join("output", i.Outfile)

		dir := filepath.Dir(filePath)
		if _, err := os.Stat(dir); os.IsNotExist(err) {
			err := os.MkdirAll(dir, 0777)
			if err != nil {
				Err(fmt.Sprintf("Error creating output directory: %s", err))
				return
			}
		}
		var err error
		f, err = os.Create(filePath)
		if err != nil {
			Err(fmt.Sprintf("Error creating output file: %s", err))
			return
		}
		defer f.Close()
	}

	if f != nil {
		fmt.Fprintf(f, "%s", fmt.Sprintln(a...))
	}
}

func Stderr(i Instance, a ...interface{}) {
	logger.Printf("%s%s:%s%s\n%s", tabs, BrightRed("[STDERR"), Summary(i), BrightRed("]"), fmt.Sprintln(a...))
}

func Crit(i Instance, a ...interface{}) {
	logger.Printf("%s%s:%s%s %s", tabs, Red("[CRIT"), Summary(i), Red("]"), fmt.Sprintln(a...))
}

func Err(a ...interface{}) {
	if !*SuperQuietOut {
		logger.Printf("%s%s %s", tabs, BrightRed("[ERROR]"), fmt.Sprintln(a...))
	}
}

func ErrExtra(i Instance, a ...interface{}) {
	if !*SuperQuietOut {
		logger.Printf("%s%s:%s%s %s", tabs, BrightRed("[ERROR"), Summary(i), BrightRed("]"), fmt.Sprintln(a...))
	}
}

func Fatal(a ...interface{}) {
	logger.Printf("%s%s %s", tabs, BrightRed("[FATAL]"), fmt.Sprintln(a...))
	os.Exit(1)
}

func Warning(a ...interface{}) {
	if !*SuperQuietOut {
		logger.Printf("%s%s %s", tabs, Yellow("[WARN]"), fmt.Sprintln(a...))
	}
}

func Info(a ...interface{}) {
	if !*QuietOut && !*SuperQuietOut {
		logger.Printf("%s%s %s", tabs, BrightCyan("[INFO]"), fmt.Sprintln(a...))
	}
}

func InfoExtra(i Instance, a ...interface{}) {
	if !*QuietOut&& !*SuperQuietOut {
		logger.Printf("%s%s:%s%s %s", tabs, BrightCyan("[INFO"), Summary(i), BrightCyan("]"), fmt.Sprintln(a...))
	}
}

func Debug(a ...interface{}) {
	if *DebugOut {
		logger.Printf("%s%s %s", tabs, Cyan("[DEBUG]"), fmt.Sprintln(a...))
	}
}

func DebugExtra(i Instance, a ...interface{}) {
	if *DebugOut {
		logger.Printf("%s%s:%s%s %s", tabs, Cyan("[DEBUG"), Summary(i), Cyan("]"), fmt.Sprintln(a...))
	}
}

func Summary(i Instance) string {
	if i.Script == "" {
		return fmt.Sprintf("%d:%s:%s", Blue(i.ID), BrightRed(i.Username), BrightGreen(i.IP))
	}
	return fmt.Sprintf("%d@%s:%s:%s:%s/%s", Blue(i.ID), Time(), BrightRed(i.Username), BrightGreen(i.IP), BrightGreen(i.Hostname), BrightBlue(i.Script))
}
