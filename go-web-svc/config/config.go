/* File: config.go

Description:
 This file is used to read the data from config.yaml and create a config.
*/

package config

import (
	"fmt"

	"github.com/spf13/viper"
)

type Databases struct {
	Mysql Mysql `yaml:"mysql"`
	Mongo Mongo `yaml:"mongo"`
}
type Mysql struct {
	Host     string `yaml:"host"`
	Port     int    `yaml:"port"`
	User     string `yaml:"user"`
	Password string `yaml:"password"`
	Database string `yaml:"database"`
}
type Mongo struct {
	Host       string `yaml:"host"`
	Port       int    `yaml:"port"`
	Database   string `yaml:"database"`
	Collection string `yaml:"collection"`
}

func BuildConfig() (*Databases, error) {
	viper.SetConfigName("config")
	viper.AddConfigPath("/app/config")
	viper.AddConfigPath("./config")

	viper.AutomaticEnv()
	err1 := viper.BindEnv("mysql.host", "MYSQL_HOST")
	if err1 != nil {
		panic(fmt.Errorf("Error mysql host: %s \n", err1))
	}

	err := viper.ReadInConfig()
	if err != nil {
		panic(fmt.Errorf("Error config file: %s \n", err))
	}

	var config Databases

	err = viper.Unmarshal(&config)
	if err != nil {
		panic(fmt.Errorf("Unable to decode Config: %s \n", err))
	}

	return &config, err

}
