// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import 'jquery'
import "jquery_ujs"
import "popper"
import "bootstrap"

import "./add_jquery.js"

import {TabulatorFull as Tabulator} from 'tabulator-tables';
window.Tabulator = Tabulator;

window.bootstrap = bootstrap