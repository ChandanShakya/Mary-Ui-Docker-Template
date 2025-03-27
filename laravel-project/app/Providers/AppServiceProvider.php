<?php

namespace App\Providers;

use Illuminate\Support\Facades\URL;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        // Disable query log to reduce memory usage in production
        if (app()->environment('production')) {
            DB::disableQueryLog();
        }
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Limit maximum string length for database columns (improves performance)
        Schema::defaultStringLength(191);

        // Disable model events when running in production (reduces overhead)
        if (app()->environment('production')) {
            \Illuminate\Database\Eloquent\Model::preventLazyLoading();
        }
    }
}
